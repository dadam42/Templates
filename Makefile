#### - Start of actual module's parameters
# Optional, set if modules must produce executable
NAME = wow#

# Name of the directory containing sources for the module, no trailing slash.
SRCS_DIR = .#

# If NAME is set, the file containing .c must be the first in the list
# Files borrowed to sub-modules _must_ be mentionned with their module's directory
# e.g. sub_module_dir/file.c
RAW_SRCS = main.c a.c b.c c.c mod1/d.c#
# Optionnal list of directories for #include preprocessor directive
INCLUDES = #

# Optionnal list of sub-modules directories
MOD_DIRS = mod1 mod2#

LDIRS = #
LIBS = #
#### - End of actual module's parameters

# Pre definition of modules' rules.
define MOD_RULE
$(1)/%.o:
	$(MAKE) -C $(1) $$*.o
endef

# Not sure if it is useful...
# Filter real module's files from sub-modules' files.
mod_pattern := $(MOD_DIRS:%:%/%)
MOD_FILES := $(filter $(mod_pattern), $(RAW_SRCS))
SRCS_FILES := $(filter-out $(mod_pattern), $(RAW_SRCS))
OBJ_FILES = $(SRCS_FILES:%.c=%.o) $(MOD_FILES:%.c=%.o)

# Trick from http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/#combine 
# to handle dependancies, the trick is used every where a (*) symbol appear.
DEP_DIR = .cdependancies#
DEP_FLAGS = -MT $@ -MMD -MP -MF $(DEP_DIR)/$*.d

CC = gcc#
CFLAGS = -Wall -Werror -Wextra#
LKFLAGS = $(LIBS:lib%=-l%)#
LDFLAGS = $(LDIRS:%=-L%)
COMPFLAGS = $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LKFLAGS)#

.PHONY: all
ifndef NAME
all : $(OBJ_FILES)

else
all : $(NAME)

$(NAME): $(OBJ_FILES)
	echo "UNMODE NAME RULE"
	$(CC) $^ -o $@
endif

#(*)
%.o : %.c

#(*)
%.o : $(SRCS_DIR)/%.c $(DEP_DIR)/%.d | $(DEP_DIR)
	$(CC) $(DEP_FLAGS) $(COMPFLAGS) -c $<

# Real definition of modules' rules.
$(foreach mod, $(MOD_DIRS), $(eval $(call MOD_RULE, $(mod))))

#(*)
$(DEP_DIR): ; mkdir -p $@

.PHONY: $(LIBS)
lib% :
	$(MAKE) -C $@

.PHONY: clean
clean:
	rm -f $(wildcard $(OBJ_FILES))
	rm -rf $(DEP_DIR)

.PHONY: fclean
fclean: clean
	rm -f $(NAME)

.PHONY: re
re: fclean $(NAME)

a.c:
	if [ ! -s a.c ] ; then ; touch a.c ; echo '#include "a.h"; #include "b.h"; #include "c.h"' >> a.c ; fi

b.c:
	if [ ! -s b.c ] ; then ; touch b.c ; echo '#include "b.h"; #include "c.h"' >> b.c ; fi

c.c: 
	if [ ! -s c.c ] ; then ; touch c.c ; echo '#include "c.h"' >> c.c ; fi

#(*)
DEP_FILES := $(SRCS_FILES:%.c=$(DEP_DIR)/%.d)
$(DEP_FILES):
include $(wildcard $(DEP_FILES))
