// usage: proxyctl on [host port] | off | set host port | status | get | dump   (setuid root; Wi-Fi = en0)
#import <Foundation/Foundation.h>

// the iOS SDK marks SCPreferences unavailable, but the symbols exist at runtime
typedef const struct __SCPreferences *SCPreferencesRef;
#define SC(ret, name, args) extern ret name args __asm("_" #name)
SC(SCPreferencesRef, SCPreferencesCreate, (CFAllocatorRef, CFStringRef, CFStringRef));
SC(CFPropertyListRef, SCPreferencesPathGetValue, (SCPreferencesRef, CFStringRef));
SC(Boolean, SCPreferencesPathSetValue, (SCPreferencesRef, CFStringRef, CFDictionaryRef));
SC(Boolean, SCPreferencesLock, (SCPreferencesRef, Boolean));
SC(Boolean, SCPreferencesUnlock, (SCPreferencesRef));
SC(Boolean, SCPreferencesCommitChanges, (SCPreferencesRef));
SC(Boolean, SCPreferencesApplyChanges, (SCPreferencesRef));

int main(int argc, char **argv) {
	@autoreleasepool {
		setuid(0); setgid(0);
		if (argc < 2) return 2;
		NSString *cmd = @(argv[1]);
		SCPreferencesRef p = SCPreferencesCreate(NULL, CFSTR("proxyctl"), NULL);
		NSDictionary *svcs = (__bridge NSDictionary *)SCPreferencesPathGetValue(p, CFSTR("/NetworkServices"));
		// iOS has several en0 services (the count varies per device) and only one is live, so write all of them
		if ([cmd isEqual:@"services"]) { // debug: every service with its device, name and proxy dict
			for (NSString *k in svcs) printf("%s dev=%s name=%s proxies=%s\n", k.UTF8String, [svcs[k][@"Interface"][@"DeviceName"] description].UTF8String, [svcs[k][@"UserDefinedName"] description].UTF8String, [[svcs[k][@"Proxies"] description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "].UTF8String);
			return 0;
		}
		NSMutableArray<NSString *> *paths = [NSMutableArray array];
		for (NSString *k in svcs)
			if ([svcs[k][@"Interface"][@"DeviceName"] isEqual:@"en0"])
				[paths addObject:[[@"/NetworkServices/" stringByAppendingPathComponent:k] stringByAppendingPathComponent:@"Proxies"]];
		if (!paths.count) { fprintf(stderr, "no Wi-Fi service\n"); return 1; }
		NSDictionary *(^cur)(NSString *) = ^NSDictionary *(NSString *path) { return (__bridge NSDictionary *)SCPreferencesPathGetValue(p, (__bridge CFStringRef)path); };
		NSMutableDictionary *d = [NSMutableDictionary dictionary]; // the service that has a proxy, else any: what status/get report
		for (NSString *path in paths) if (cur(path)[@"HTTPProxy"]) { [d setDictionary:cur(path)]; break; }

		// Settings treats the proxy as Manual while HTTPProxy exists, so Off must delete the keys.
		// The last host/port live here so a bare `on` (and the app's fields) can restore them.
		NSString *saved = @"/var/jb/var/mobile/Library/Preferences/com.atreb92.crappyproxy.plist";
		NSDictionary *last = [NSDictionary dictionaryWithContentsOfFile:saved];
		NSString *host = d[@"HTTPProxy"] ?: last[@"host"] ?: @"";
		int port = d[@"HTTPPort"] ? [d[@"HTTPPort"] intValue] : [last[@"port"] intValue];

		if ([cmd isEqual:@"status"]) { puts([d[@"HTTPEnable"] intValue] ? "1" : "0"); return 0; }
		if ([cmd isEqual:@"dump"]) { puts(d.description.UTF8String); return 0; }
		if ([cmd isEqual:@"get"]) { printf("%s %d\n", host.UTF8String, port); return 0; }

		if ([cmd isEqual:@"set"]) { // remember a proxy for the next `on` without touching the live config
			if (argc < 4 || !atoi(argv[3])) return 2;
			return [@{@"host": @(argv[2]), @"port": @(atoi(argv[3]))} writeToFile:saved atomically:YES] ? 0 : 1;
		}

		if (![cmd isEqual:@"on"] && ![cmd isEqual:@"off"]) return 2; // unknown command: don't fall through to off
		BOOL on = [cmd isEqual:@"on"];
		if (on && argc >= 4) { host = @(argv[2]); port = atoi(argv[3]); }
		if (on && (!host.length || !port)) { fprintf(stderr, "no host/port set: proxyctl on HOST PORT\n"); return 1; }
		[@{@"host": host, @"port": @(port)} writeToFile:saved atomically:YES];

		if (!SCPreferencesLock(p, true)) return 1;
		for (NSString *path in paths) {
		NSMutableDictionary *d = [cur(path) mutableCopy] ?: [NSMutableDictionary dictionary];
		[d removeObjectsForKeys:@[@"HTTPEnable", @"HTTPProxy", @"HTTPPort", @"HTTPSEnable", @"HTTPSProxy", @"HTTPSPort", @"HTTPProxyAuthenticated", @"HTTPProxyUsername"]];
		d[@"ExceptionsList"] = @[@"*.local", @"169.254/16"]; // the keys Settings itself writes
		d[@"FTPPassive"] = @1;
		if (on) {
			d[@"HTTPEnable"] = d[@"HTTPSEnable"] = @1;
			d[@"HTTPProxy"] = d[@"HTTPSProxy"] = host;
			d[@"HTTPPort"] = d[@"HTTPSPort"] = @(port);
		}

		SCPreferencesPathSetValue(p, (__bridge CFStringRef)path, (__bridge CFDictionaryRef)d);
		}
		BOOL ok = SCPreferencesCommitChanges(p) && SCPreferencesApplyChanges(p);
		SCPreferencesUnlock(p);
		return ok ? 0 : 1;
	}
}
