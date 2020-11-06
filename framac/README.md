## Frama-C dependencies directory

This directory handle the following contents:

### dedicated includes

   * libxDCI direct external dependencies (USB driver, libc) that need to be annotated in order to complète libxDCI functions specifications
   * libxDCI environment configuration (generated by the Wookey SDK Kconfig mechanism) which generate the libxDCI configuration profile. A frama-C dedicated one is stored here to keep it separated from the production ones
   * Frama-C specific primitives

### local frama-C sessions file

Handling the results of the successive Frama-C execution

### Others

Notes and other informational content.

### out of tree

create repository framac_include out of libxcdi repository then export env variable in order to create makefile targets (examples) :

export FRAMAC_TARGET=y
export USBOTGHS_DIR=~/Documents/stage/GIT/driver-stm32f4xx-usbotghs
export USBOTGHS_DEVHEADER_PATH=~/Documents/stage/GIT/framac_include/
export LIBSTD_API_DIR=~/Documents/stage/GIT/framac_include/libstd/api/
export EWOK_API_DIR=~/Documents/stage/GIT/framac_include/