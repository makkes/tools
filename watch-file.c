#include <stdio.h>
#include <sys/inotify.h>
#include <unistd.h>

#define EVENT_SIZE ( sizeof( struct inotify_event ) )
#define BUFLEN ( 1024 * ( EVENT_SIZE + 16 ) )

short file_exists(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file) {
	fclose(file);
	return 1;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    int length, i = 0;
    int fd;
    int wd;
    short add_watch = 1;
    char buffer[BUFLEN];

    fd = inotify_init();
    if (fd < 0) {
	perror("inotify_init");
    }

    if(!file_exists(argv[1])) {
        fprintf(stderr, "File '%s' doesn't exist, exiting\n", argv[1]);
        return 1;
    }

    printf("Start watching '%s'\n", argv[1]);

    while (1) {
	if (add_watch) {
            if(!file_exists(argv[1])) {
                fprintf(stderr, "File doesn't exist, exiting\n");
                return 1;
            }
	    wd = inotify_add_watch(fd, argv[1],
				   IN_OPEN | IN_CLOSE_WRITE |
				   IN_CLOSE_NOWRITE | IN_ACCESS | IN_MODIFY
				   | IN_CREATE | IN_DELETE);
	    add_watch = 0;
	}

	i = 0;
	length = read(fd, buffer, BUFLEN);
	if (length < 0) {
	    perror("read");
	}

	while (i < length) {
	    struct inotify_event *event =
		(struct inotify_event *) &buffer[i];
	    if (event->mask & IN_CREATE) {
		printf("File was created\n");
	    } else if (event->mask & IN_DELETE) {
		printf("File was deleted\n");
	    } else if (event->mask & IN_MODIFY) {
		printf("File was modified\n");
	    } else if (event->mask & IN_ACCESS) {
		printf("File was accessed\n");
	    } else if (event->mask & IN_OPEN) {
		printf("File was opened\n");
	    } else if (event->mask & IN_CLOSE_WRITE
		       || event->mask & IN_CLOSE_NOWRITE) {
		printf("File was closed\n");
	    } else if (event->mask & IN_IGNORED) {
		printf("File was ignored, retrying watch\n");
		add_watch = 1;
	    } else {
		printf("Unknown event: %d", event->mask);
	    }
	    i += EVENT_SIZE + event->len;
	}
    }
    inotify_rm_watch(fd, wd);
    close(fd);

    return 0;
}
