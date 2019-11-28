### - Start of actual module's parameters
# Optional, set if modules must produce executable
NAME = wow#

# Name of the directory containing sources for the module, no trailing slash.
SRCS_DIR = .#

#List of .c files to compile for NAME, leave it blank if you want all the .c files in SRCS_DIR
SRCS = #

# Optionnal list of directories for #include preprocessor directive
INCLUDES = #

# Optionnal list of sub-modules directories
MOD_DIRS = mod#

LDIRS = #
LIBS = #
#### - End of actual module's parameters

# Pre definition of modules' rules.
define MOD_RULE
.PHONY: $(1)
$(1):
	$(MAKE) -C $(1) 

$(1)/%.o: $(1)/%.c
	$(MAKE) -C $(1) $$*.o
endef

MOD_FILES := $(foreach mod, $(MOD_DIRS),$(wildcard $(mod)/*.c))
SRCS_FILES := $(if $(SRCS), $(wildcard $(SRCS:%=$(SRCS_DIR)/%)), $(wildcard $(SRCS_DIR)/*.c))
OBJ_SRCS := $(SRCS_FILES:%.c=%.o)
OBJ_MOD := $(MOD_FILES:%.c=%.o)

# Trick from http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/#combine 
# to handle dependancies, the trick is used every where a (*) symbol appear.
DEP_DIR = .cdependancies#
DEP_FLAGS = -MT $@ -MMD -MP -MF $(DEP_DIR)/$*.d

CC = gcc#
CFLAGS = -Wall -Werror -Wextra#
LKFLAGS = $(LIBS:lib%=-l%)#
LDFLAGS = $(LDIRS:%=-L%)
IFLAGS = $(INCLUDES:%=-I%) $(MOD_DIRS:%=-I%)
COMPFLAGS = $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LKFLAGS)#

.PHONY: all
ifndef NAME
all : $(OBJ_FILES)

else
all : $(NAME)

$(NAME): $(OBJ_FILES) $(MOD_DIRS)
	$(CC) $(OBJ_FILES) $(OBJ_MOD) -o $@
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
