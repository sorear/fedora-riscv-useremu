#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <errno.h>
#include <fcntl.h>

#define REGISTRATION ":riscv64:M::\\x7f\\x45\\x4c\\x46\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xf3\\x00:\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xff\\xff:/usr/bin/qemu-riscv64:"

void clear_old_riscv64() {
	/* silently */
	int fd;
	fd = open("/proc/sys/fs/binfmt_misc/riscv64", O_WRONLY);
	if (fd < 0) return;
	write(fd, "-1", 2);
	close(fd);
}

int reregister() {
	int fd,res;
	if (access("/proc/version", F_OK) < 0 && errno == ENOENT) {
		res = mount("proc", "/proc", "proc", 0, "");
		if (res < 0) {
			perror("mount /proc");
			return -1;
		}
	}
	if (access("/proc/sys/fs/binfmt_misc/register", F_OK) < 0 && errno == ENOENT) {
		res = mount("binfmt_misc", "/proc/sys/fs/binfmt_misc", "binfmt_misc", 0, "");
		if (res < 0) {
			perror("mount /proc/sys/fs/binfmt_misc");
			return -1;
		}
	}
	clear_old_riscv64();
	fd = open("/proc/sys/fs/binfmt_misc/register", O_WRONLY);
	if (fd < 0) {
		perror("open /proc/sys/fs/binfmt_misc/register");
		return -1;
	}
	if (write(fd, REGISTRATION "\n", sizeof(REGISTRATION "\n") - 1) < 0) {
		perror("write /proc/sys/fs/binfmt_misc/register");
		close(fd);
		return -1;
	}
	close(fd);
	return 0;
}

static void try_run_user(int argc, char** argv) {
	/* check if arch emu works */
	pid_t ch = fork();
	int status;
	if (ch < 0) {
		perror("fork");
		_exit(1); /* no sense even continuing; exit parent */
	}
	if (ch == 0) {
		execl("/bin/true", "true", (void*)0);
		perror("exec");
		_exit(1);
	}
	if (wait(&status) < 0) {
		perror("wait");
		_exit(1); /* no sense even continuing; exit parent */
	}
	if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
		/* arch emu works; run user program */
		static char* default_argv[] = {"", "bash", 0};
		if (argc <= 1) {
			argv = default_argv;
		}
		execvp(argv[1], argv+1);
		perror("exec");
		_exit(1); /* whatever this is, it's not an emul problem */
	}
}

int main(int argc, char** argv) {
	try_run_user(argc, argv);

	fputs("\n\
Starting architecture emulation failed.  Attempting to reconfigure the\n\
binfmt_misc mapping for RISC-V ELF files.\n\n", stderr);
	if (reregister() == 0) {
		try_run_user(argc, argv);
	}

	fputs("\n\
Starting architecture emulation failed.  binfmt_misc configuration requires\n\
true root privileges, and is not effective in sandboxed root environments\n\
such as is provided by Docker by default.  You will need to run the following\n\
command as root on the Docker host machine:\n\
\n\
     echo '" REGISTRATION "' > /proc/sys/fs/binfmt_misc/register\n\
\n\
It is also possible to run this container with --privileged; this might be\n\
useful for Docker on Mac or Docker on Windows.\n\n", stderr);
	return 1;

}
