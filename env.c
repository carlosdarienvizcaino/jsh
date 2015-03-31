/*
 * printenv.c
 *
 *  Created on: Mar 29, 2015
 *      Author: joe
 */

#include "env.h"
#include "defines.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


extern char** environ;

void printEnv() {
	char** env;
	for(env = environ; *env; ++env) {
		printf("%s\n", *env);
	}
}

void printEnvSingleVar(char* variable) {
	char** env;
	char* envLinePtr;

	for (env = environ; *env; ++env) {
		envLinePtr = *env;
		while (*envLinePtr != '\0' && *variable != '\0' && *envLinePtr == *variable) {
			++envLinePtr;
			++variable;

			if (*envLinePtr == '=') {
				printf("%s\n", envLinePtr + 1);
				return;
			}
		}
	}
}

void setEnv(const char* variable, const char* word) {
	int val = setenv(variable, word, 1);
	printf("Output of setEnv: %d\n", val);
}

void unsetEnv(const char* variable) {
	int val = unsetenv(variable);
	printf("Output of unsetEnv: %d\n", val);
}

char* expandVariables(char* word) {
	char* copy = malloc(MAX_LENGTH);
	int copyPtr = 0;
	int i;

	for (i = 0; i < MAX_LENGTH && word[i] != '\0'; ++i) {
		if (word[i] == '$' && word[i + 1] == '{') {
			char* envVar = malloc(MAX_LENGTH);
			int envVarPtr = 0;
			i += 2;
			while (i < MAX_LENGTH && word[i] != '\0' && word[i] != '}') {
				envVar[envVarPtr] = word[i];
				++envVarPtr;
				++i;
				if (word[i] == '}') {
					envVar[envVarPtr] = '\0';
					char* temp = malloc(MAX_LENGTH);
					sprintf(temp, "%s", getenv(envVar));
					int j;
					for (j = 0; j < strlen(temp); ++j) {
						copy[copyPtr] = temp[j];
						++copyPtr;
					}
					free(temp);
					free(envVar);
					envVarPtr = 0;
				}
			}
			++i;
		}
		else {
			copy[copyPtr] = word[i];
			++copyPtr;
		}
	}
	free(word);
	return copy;
}