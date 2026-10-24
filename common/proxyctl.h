// iOS has no /bin/sh, so popen()/system() can't work: spawn proxyctl directly.
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/wait.h>
#import <unistd.h>

extern char **environ;

// runs proxyctl with args (NULL-terminated), returns trimmed stdout ("" on failure)
static inline NSString *proxyctl(const char *a1, const char *a2, const char *a3) {
	const char *argv[] = {"proxyctl", a1, a2, a3, NULL};
	int fd[2];
	if (pipe(fd)) return @"";
	posix_spawn_file_actions_t fa;
	posix_spawn_file_actions_init(&fa);
	posix_spawn_file_actions_adddup2(&fa, fd[1], 1);
	posix_spawn_file_actions_addclose(&fa, fd[0]);
	pid_t pid;
	int rc = posix_spawn(&pid, "/var/jb/usr/bin/proxyctl", &fa, NULL, (char *const *)argv, environ);
	posix_spawn_file_actions_destroy(&fa);
	close(fd[1]);
	char buf[256] = {0};
	if (!rc) { read(fd[0], buf, sizeof buf - 1); waitpid(pid, NULL, 0); }
	close(fd[0]);
	return [@(buf) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
