/*
 *
 * Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
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
 * This file has been generated by devheader.py from a Tataouine SDK Json layout file
 *
 */
#ifndef USB_OTG_HS_H_
# define USB_OTG_HS_H_

#include "generated/devinfo.h"

# define USB_OTG_HS_BASE 0x40040000
#define OTG_HS_IRQ 93
#define OTG_HS_WKUP_IRQ 92
#define OTG_HS_EP1_IN_IRQ 91
#define OTG_HS_EP1_OUT_IRQ 90
/* naming indexes in structure gpios[] table */
#define USB_HS_ULPI_D0 0
#define USB_HS_ULPI_CLK 1
#define USB_HS_ULPI_D1 2
#define USB_HS_ULPI_D2 3
#define USB_HS_ULPI_D3 4
#define USB_HS_ULPI_D4 5
#define USB_HS_ULPI_D5 6
#define USB_HS_ULPI_D6 7
#define USB_HS_ULPI_D7 8
#define USB_HS_ULPI_STP 9
#define USB_HS_ULPI_DIR 10
#define USB_HS_ULPI_NXT 11
#define USB_HS_RESET 12

static const struct user_driver_device_infos usb_otg_hs_dev_infos = {
    .address = 0x40040000,
    .size    = 0x40000,
    .id      = 7,
    .gpios = {
      { GPIO_PA, 3 },
      { GPIO_PA, 5 },
      { GPIO_PB, 0 },
      { GPIO_PB, 1 },
      { GPIO_PB, 10 },
      { GPIO_PB, 11 },
      { GPIO_PB, 12 },
      { GPIO_PB, 13 },
      { GPIO_PB, 5 },
      { GPIO_PC, 0 },
      { GPIO_PC, 2 },
      { GPIO_PC, 3 },
      { GPIO_PC, 1 },
      { 0, 0 },
    }
};


#endif
