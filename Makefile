SRCS = dc.erl lock2key.erl hub_fsm.erl

BEAMS = $(SRCS:.erl=.beam)

TOP_DIR = $(CURDIR)
EBIN_DIR = $(TOP_DIR)/ebin
SRC_DIR = $(TOP_DIR)/src

all: $(BEAMS)
clean:
	rm ebin/*

%.erl:
	erlc -o $(EBIN_DIR) $(SRC_DIR)/$@ 

$(BEAMS): $(SRCS)

