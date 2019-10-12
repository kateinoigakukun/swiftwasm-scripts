CLANG?=clang
SYSROOT?=/opt/wasi-sdk/share/sysroot
OBJDIR   = ./obj
SOURCES  = $(wildcard ./swiftwasm-wasi-stubs/*.c)
OBJECTS  = $(addprefix $(OBJDIR)/, $(SOURCES:./swiftwasm-wasi-stubs/%.c=%.o))

prebuild: $(OBJECTS)

$(OBJDIR)/%.o: swiftwasm-wasi-stubs/%.c
	$(CLANG) -target wasm32-wasm --sysroot $(SYSROOT) -o $@ -c $<
