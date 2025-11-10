#include "portio.h"

#include <stdio.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_system.h>
#include <esp_log.h>
#include <driver/uart.h>

#define BAUD 460800

static const char *TAG = "CONSOLE_ECHO";

extern "C" void app_main(void)
{
#if 0
  ESP_LOGI(TAG, "Hello World from ESP-IDF (C++)!");
  ESP_LOGI(TAG, "Console Echo Ready - Type characters to see them echoed back");
  ESP_LOGI(TAG, "Free heap: %lu bytes", esp_get_free_heap_size());
#endif

  // Configure UART for console (usually UART0)
  uart_config_t uart_config = {
    .baud_rate = BAUD,
    .data_bits = UART_DATA_8_BITS,
    .parity = UART_PARITY_DISABLE,
    .stop_bits = UART_STOP_BITS_1,
    .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
    .source_clk = UART_SCLK_DEFAULT,
  };

  uart_driver_install(UART_NUM_0, 256, 0, 0, NULL, 0);
  uart_param_config(UART_NUM_0, &uart_config);

  uint8_t data[1];

  while (1) {
    size_t avail = 0;
    uart_get_buffered_data_len(UART_NUM_0, &avail);
    if (avail) {
      int len = uart_read_bytes(UART_NUM_0, data, 1, 0);
      if (len > 0)
        port_putc(data[0]);
    }

    if (bus_available()) {
      data[0] = port_getc();
      uart_write_bytes(UART_NUM_0, (const char*)data, 1);
    }

    vTaskDelay(pdMS_TO_TICKS(10));
  }

  return;
}
