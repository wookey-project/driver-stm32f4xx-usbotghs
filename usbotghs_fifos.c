/*
 *
 * Copyright 2019 The wookey project team <wookey@ssi.gouv.fr>
 *   - Ryad     Benadjila
 *   - Arnauld  Michelizza
 *   - Mathieu  Renard
 *   - Philippe Thierry
 *   - Philippe Trebuchet
 *
 * This package is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * ur option) any later version.
 *
 * This package is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with this package; if not, write to the Free Software Foundation, Inc., 51
 * Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 *
 */

#include "libc/regutils.h"
#include "libc/types.h"
#include "libc/stdio.h"

#include "api/libusbotghs.h"
#include "usbotghs_regs.h"
#include "usbotghs.h"

#include "generated/usb_otg_hs.h"
#include "usbotghs_handler.h"

/*
 * Size of the USB OTG HS core internal FIFO
 */
#define USBOTG_HS_RX_CORE_FIFO_SZ 0x80 /* 512 bytes, unit is 32bits DWORD here */
#define USBOTG_HS_TX_CORE_FIFO_SZ 0x80 /* 512 bytes, unit is 32bits DWORD here */



mbed_error_t usbotghs_init_global_fifo(void)
{
    /*
     * 	  Set up the Data FIFO RAM for each of the FIFOs
	 *      – Program the OTG_HS_GRXFSIZ register, to be able to receive control OUT data
	 *        and setup data. If thresholding is not enabled, at a minimum, this must be equal to
	 *        1 max packet size of control endpoint 0 + 2 Words (for the status of the control
	 *        OUT data packet) + 10 Words (for setup packets).
	 *
	 * See reference manual section 34.11 for peripheral FIFO architecture.
	 * XXX: The sizes of TX FIFOs seems to be the size of TX FIFO #0 for
	 * all FIFOs. We don't know if it is really the case or if the DTXFSTS
	 * register does not give the free space for the right FIFO.
	 *
	 * 0                512                1024             1536
	 * +-----------------+------------------+-----------------+-----------
	 * |     RX FIFO     |     TX0 FIFO     | TXi FIFO (EP i) |
	 * |    128 Words    |    128 Words     |    128 Words    |...
	 * +-----------------+------------------+-----------------+------------
     * Settings FIFOs for Endpoint 0
     * RXFD (RxFIFO depth, in 32bits DWORD)
     */
	set_reg(r_CORTEX_M_USBOTG_HS_GRXFSIZ, USBOTG_HS_RX_CORE_FIFO_SZ, USBOTG_HS_GRXFSIZ_RXFD);

    return MBED_ERROR_NONE;
}

mbed_error_t usbotghs_set_epx_fifo(usbotghs_ep_t *ep)
{
    if (ep->id == 0) {
        /*
         * EndPoint 0 TX FIFO configuration (should store a least 4 64byte paquets)
         */
        set_reg(r_CORTEX_M_USBOTG_HS_DIEPTXF0, USBOTG_HS_TX_CORE_FIFO_SZ, USBOTG_HS_DIEPTXF_INEPTXSA);
        set_reg(r_CORTEX_M_USBOTG_HS_DIEPTXF0, USBOTG_HS_TX_CORE_FIFO_SZ, USBOTG_HS_DIEPTXF_INEPTXFD);
        /*
         * 4. Program STUPCNT in the endpoint-specific registers for control OUT endpoint 0 to receive a SETUP packet
         *      – STUPCNT = 3 in OTG_HS_DOEPTSIZ0 (to receive up to 3 back-to-back SETUP packets)
         */
        set_reg(r_CORTEX_M_USBOTG_HS_DOEPTSIZ(0),
                3, USBOTG_HS_DOEPTSIZ_STUPCNT);
        set_reg(r_CORTEX_M_USBOTG_HS_DOEPCTL(0),
                1, USBOTG_HS_DOEPCTL_CNAK);
    } else {
        /* all other EPs have their DIEPTXF registers accesible through a single macro */
        set_reg(r_CORTEX_M_USBOTG_HS_DIEPTXF(ep->id), ep->mpsize, USBOTG_HS_DIEPTXF_INEPTXSA);
        set_reg(r_CORTEX_M_USBOTG_HS_DIEPTXF(ep->id), ep->mpsize, USBOTG_HS_DIEPTXF_INEPTXFD);
    }
    return MBED_ERROR_NONE;
}

