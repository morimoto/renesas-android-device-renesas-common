/*
* Copyright (C) 2018, 2019 GlobalLogic

* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#include <sys/stat.h>

#define RAMOOPS_SYSFS_DIR  "/sys/fs/pstore/"
#define LOG_FOLDER         "/data/vendor/ramoops_logger/"
#define FNAME_MAGIC        "ramoops_log_"

#define MAX_NAME_LEN 256

struct folder_entries {
    char **entries;
    int num_entries;
};

#define BUFFER_SIZE 1024

static int copy_file(char *dest, char *source)
{
    int in_fd, out_fd, n_bytes;
    char buf[BUFFER_SIZE];

    if((in_fd = open(source, O_RDONLY)) == -1) {
        printf("Cannot open %s\n", source);
        return -1;
    }

    if((out_fd = creat(dest, S_IRWXU)) == -1) {
        printf("Cannot create %s\n", dest);
        return -1;
    }

    while((n_bytes = read(in_fd, &buf[0], BUFFER_SIZE)) > 0) {
        if(write(out_fd, &buf[0], n_bytes) != n_bytes ) {
            printf("Write error to %s\n", dest);
            return -1;
        }

        if(n_bytes == -1) {
            printf("Read error from %s\n", source);
            return -1;
        }
    }

    if(close(in_fd) == -1 || close(out_fd) == -1) {
        printf("Error closing files\n");
        return -1;
    }

    return 0;
}

static int get_num_files_from_dir(char *path)
{
    DIR *d;
    struct dirent *dir;
    int i = 0;

    d = opendir(path);

    if (d) {
        while((dir = readdir(d)) != NULL) {
            if (memcmp(dir->d_name, ".", 1) && memcmp(dir->d_name, "..", 2))
                i++;
        }
        closedir(d);
    }

    return i;
}

static uint64_t get_fd_id(char **fds, int num_entries)
{
    int i = 0;
    char *substr = NULL;
    uint64_t curr_num = 0;
    uint64_t max_num = 0;

    for (i = 0; i < num_entries; ++i) {
        substr = strstr(fds[i], FNAME_MAGIC);
        if (!substr)
            continue;
        curr_num = strtoull(substr + strlen(FNAME_MAGIC), NULL, 10);
        if (curr_num > max_num)
            max_num = curr_num;
    }

    ++max_num;

    return max_num;
}

static int get_files_from_dir(char **buf, char *path)
{
    DIR *d;
    struct dirent *dir;
    int i = 0;

    d = opendir(path);
    if (d) {
        while((dir = readdir(d)) != NULL) {
            if (memcmp(dir->d_name, ".", 1) && memcmp(dir->d_name, "..", 2)) {
                memcpy(buf[i], dir->d_name, strlen(dir->d_name) + 1);
                i++;
            }
        }
        closedir(d);
    } else {
        return -1;
    }

    return 0;
}

static void del_fd_entr(struct folder_entries *fd_entr)
{
    int i = 0;

    for (i = 0; i < fd_entr->num_entries; ++i)
        free(fd_entr->entries[i]);

    free(fd_entr->entries);
    free(fd_entr);
}

static struct folder_entries *init_fd_entr(char *path)
{
    struct folder_entries *fd_entr;
    int i = 0;
    int num_entries = get_num_files_from_dir(path);

    fd_entr = (struct folder_entries *)malloc(sizeof(struct folder_entries));
    if (!fd_entr) {
        printf("[%s: %d] FAILED to allocate memory\n", __func__, __LINE__);
        return NULL;
    }

    memset(fd_entr, 0, sizeof(struct folder_entries));

    fd_entr->entries = (char **)malloc(sizeof(char *)* num_entries);
    if (!fd_entr->entries) {
        printf("[%s: %d] FAILED to allocate memory\n", __func__, __LINE__);
        free(fd_entr);
        return NULL;
    }

    for (i = 0; i < num_entries; i++) {
        fd_entr->entries[i] = (char *)malloc(MAX_NAME_LEN);
        if (!fd_entr->entries[i]) {
            printf("[%s: %d] FAILED to allocate memory\n", __func__, __LINE__);
            del_fd_entr(fd_entr);
            return NULL;
        }
        fd_entr->num_entries++;
    }

    if (get_files_from_dir(fd_entr->entries, path)) {
        printf("Failed to getting info about %s dir\n", path);
        del_fd_entr(fd_entr);
        return NULL;
    }

    return fd_entr;
}

static int create_rammops_dir(char *dir_name)
{
    struct folder_entries *fd_entr = NULL;
    uint64_t file_id = 0;
    int status = 0;

    fd_entr = init_fd_entr(LOG_FOLDER);

    if (fd_entr && fd_entr->num_entries)
        file_id = get_fd_id(fd_entr->entries, fd_entr->num_entries);
    else
        file_id = 0;

    sprintf(dir_name, "%s%s%06lu/", LOG_FOLDER, FNAME_MAGIC, file_id);

    status = mkdir(dir_name, S_IRWXU);

    del_fd_entr(fd_entr);

    return status;
}

int main(void)
{
    struct folder_entries *fd_entr = NULL;
    char fd_name[MAX_NAME_LEN];
    char in_file[MAX_NAME_LEN];
    char out_file[MAX_NAME_LEN];
    int i = 0;

    fd_entr = init_fd_entr(RAMOOPS_SYSFS_DIR);
    if (!fd_entr)
        return EXIT_FAILURE;

    if (!fd_entr->num_entries)
        goto exit;

    if (create_rammops_dir(&fd_name[0])) {
        printf("ERROR: Can't crate ramoops direcory!\n");
        goto exit;
    }

    for (i = 0; i < fd_entr->num_entries; i++) {
        sprintf(out_file, "%s%s", fd_name, fd_entr->entries[i]);
        sprintf(in_file, "%s%s", RAMOOPS_SYSFS_DIR, fd_entr->entries[i]);
        if (copy_file(out_file, in_file)) {
            printf("Can't copy %s file to %s\n", in_file, out_file);
            break;
        }
    }

exit:
    del_fd_entr(fd_entr);

    return EXIT_SUCCESS;
}