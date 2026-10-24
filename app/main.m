#import <UIKit/UIKit.h>
#import "proxyctl.h"

static NSString *const kProxies = @"proxies"; // [{name, host, port}]

@interface ProxyListVC : UITableViewController
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *proxies;
@property (nonatomic, strong) UISwitch *sw;
@property (nonatomic, copy) NSString *curHost;
@property (nonatomic) int curPort;
@end

@implementation ProxyListVC

- (instancetype)init {
	return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"CrappyProxy";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
	self.sw = [UISwitch new];
	[self.sw addTarget:self action:@selector(toggled) forControlEvents:UIControlEventValueChanged];
	[self reload];
	// the app is usually resumed, not relaunched: re-read the real state each time
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reload) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)reload {
	self.proxies = [([NSUserDefaults.standardUserDefaults arrayForKey:kProxies] ?: @[]) mutableCopy];
	NSArray *hp = [proxyctl("get", NULL, NULL) componentsSeparatedByString:@" "];
	self.curHost = hp.count == 2 ? hp[0] : @"";
	self.curPort = hp.count == 2 ? [hp[1] intValue] : 0;
	self.sw.on = [proxyctl("status", NULL, NULL) isEqual:@"1"];
	if (!self.proxies.count && self.curHost.length && self.curPort) // adopt whatever is already configured
		[self.proxies addObject:@{@"name": @"Current", @"host": self.curHost, @"port": @(self.curPort)}], [self save];
	[self.tableView reloadData];
}

- (void)save {
	[NSUserDefaults.standardUserDefaults setObject:self.proxies forKey:kProxies];
}

- (BOOL)isCurrent:(NSDictionary *)p {
	return [p[@"host"] isEqual:self.curHost] && [p[@"port"] intValue] == self.curPort;
}

- (void)applyHost:(NSString *)host port:(int)port {
	if (self.sw.on) proxyctl("on", host.UTF8String, [@(port).stringValue UTF8String]);
	else proxyctl("set", host.UTF8String, [@(port).stringValue UTF8String]);
	[self reload];
}

- (void)toggled {
	if (!self.sw.on) { proxyctl("off", NULL, NULL); return [self reload]; }
	if (!self.curHost.length || !self.curPort) {
		self.sw.on = NO;
		return [self alert:@"No proxy selected" message:@"Add a proxy with + and tap it first."];
	}
	[self applyHost:self.curHost port:self.curPort];
}

- (void)alert:(NSString *)title message:(NSString *)message {
	UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	[a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:a animated:YES completion:nil];
}

- (void)add {
	UIAlertController *a = [UIAlertController alertControllerWithTitle:@"New proxy" message:nil preferredStyle:UIAlertControllerStyleAlert];
	NSArray *ph = @[@"Name (optional)", @"Host", @"Port"];
	for (NSString *p in ph)
		[a addTextFieldWithConfigurationHandler:^(UITextField *t) {
			t.placeholder = p;
			t.autocapitalizationType = UITextAutocapitalizationTypeNone;
			t.autocorrectionType = UITextAutocorrectionTypeNo;
			if ([p isEqual:@"Port"]) t.keyboardType = UIKeyboardTypeNumberPad;
			if ([p isEqual:@"Host"]) t.keyboardType = UIKeyboardTypeURL;
		}];
	[a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	[a addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
		NSString *name = a.textFields[0].text, *host = [a.textFields[1].text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
		int port = a.textFields[2].text.intValue;
		if (!host.length || port < 1 || port > 65535) return [self alert:@"Invalid proxy" message:@"Enter a host and a port from 1 to 65535."];
		[self.proxies addObject:@{@"name": name.length ? name : host, @"host": host, @"port": @(port)}];
		[self save];
		[self.tableView reloadData];
	}]];
	[self presentViewController:a animated:YES completion:nil];
}

#pragma mark - table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return s == 0 ? 1 : self.proxies.count; }

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return s == 1 ? @"Saved proxies" : nil; }

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
	if (s == 0) return @"Applies to the Wi-Fi network you're connected to.";
	return self.proxies.count ? @"Tap a proxy to select it. Swipe to delete." : @"Tap + to add a proxy.";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
	UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
	if (ip.section == 0) {
		c.textLabel.text = @"Proxy enabled";
		c.accessoryView = self.sw;
		c.selectionStyle = UITableViewCellSelectionStyleNone;
		return c;
	}
	NSDictionary *p = self.proxies[ip.row];
	c.textLabel.text = p[@"name"];
	c.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@", p[@"host"], p[@"port"]];
	c.detailTextLabel.textColor = UIColor.secondaryLabelColor;
	c.accessoryType = [self isCurrent:p] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
	[tv deselectRowAtIndexPath:ip animated:YES];
	if (ip.section != 1) return;
	NSDictionary *p = self.proxies[ip.row];
	[self applyHost:p[@"host"] port:[p[@"port"] intValue]];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip { return ip.section == 1; }

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
	if (style != UITableViewCellEditingStyleDelete) return;
	[self.proxies removeObjectAtIndex:ip.row];
	[self save];
	[tv reloadData];
}

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o {
	self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ProxyListVC new]];
	[self.window makeKeyAndVisible];
	return YES;
}
@end

int main(int argc, char **argv) {
	@autoreleasepool { return UIApplicationMain(argc, argv, nil, @"AppDelegate"); }
}
