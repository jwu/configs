/* gpu-watch: waybar's GPU module backend. One long-lived process per module,
 * printing one JSON line every INTERVAL_MS.
 *
 * It replaces scripts/gpu.sh, which spawned bash and nvidia-smi every two
 * seconds: 16.8 ms of CPU per call, and with the usage and the temperature
 * module both running that was 1.68% of one core -- more than waybar itself
 * uses. Almost all of it is nvidia-smi's own startup (nvmlInit alone is
 * ~9.9 ms, paid on every call) plus ~5 ms for its --query-gpu sample; the same
 * two device queries in-process cost 0.017 ms, so this loop is 0.003%.
 * docs/waybar.md has the measurements.
 *
 *   gpu-watch util    ->  󰬎󰬗󰬜 11%    class "" | warning >= 70 | critical >= 90
 *   gpu-watch temp    ->  40°C      class "" | warning >= 75 | critical >= 85
 *   gpu-watch ... -once             print one line, then exit
 *
 * The driver is opened with dlopen, so nothing here links against
 * libnvidia-ml: the same binary is fine on a machine without it. When the
 * driver is missing, or a query stops answering (suspend, a driver reload), the
 * module prints the "off" line and exits. waybar's restart-interval then runs
 * it again, which is also how the device handle gets re-created after a resume.
 */

#include <dlfcn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Pango markup, the same strings gpu.sh emitted: two zero-width struts keep
 * this module's line box as tall as its neighbours (docs/waybar.md), and the
 * label is the MDI box letters "GPU" at 15pt (= 20px; Pango size has no px). */
#define STRUT "<span size='15pt'>\u200b</span><span size='15pt' rise='-1536'>\u200b</span>"
#define GPU_LABEL "<span size='15pt' rise='-1536'>\U000F0B0E\U000F0B17\U000F0B1C</span>"

/* The modules this replaces polled every 2 seconds. */
#define INTERVAL_MS 2000

#define UTIL_WARN 70
#define UTIL_CRIT 90
#define TEMP_WARN 75
#define TEMP_CRIT 85

typedef struct {
  unsigned int gpu;
  unsigned int memory;
} nvml_utilization_t;

static void *lib, *device;
static int (*nvml_init)(void);
static int (*nvml_handle)(unsigned int, void **);
static int (*nvml_utilization)(void *, nvml_utilization_t *);
static int (*nvml_temperature)(void *, int, unsigned int *);

static bool open_driver(void) {
  lib = dlopen("libnvidia-ml.so.1", RTLD_NOW | RTLD_LOCAL);
  if (lib == NULL) {
    return false;
  }
  nvml_init = dlsym(lib, "nvmlInit_v2");
  nvml_handle = dlsym(lib, "nvmlDeviceGetHandleByIndex_v2");
  nvml_utilization = dlsym(lib, "nvmlDeviceGetUtilizationRates");
  nvml_temperature = dlsym(lib, "nvmlDeviceGetTemperature");
  if (nvml_init == NULL || nvml_handle == NULL || nvml_utilization == NULL ||
      nvml_temperature == NULL) {
    return false;
  }
  if (nvml_init() != 0) {
    return false;
  }
  return nvml_handle(0, &device) == 0;
}

/* sample reports whether the driver still answers. */
static bool sample(unsigned int *util, unsigned int *temp) {
  nvml_utilization_t rates;
  if (nvml_utilization(device, &rates) != 0) {
    return false;
  }
  /* NVML_TEMPERATURE_GPU is the only sensor on a consumer card. */
  if (nvml_temperature(device, 0, temp) != 0) {
    return false;
  }
  *util = rates.gpu;
  return true;
}

static const char *classify(unsigned int value, unsigned int warn, unsigned int crit) {
  if (value >= crit) {
    return "critical";
  }
  if (value >= warn) {
    return "warning";
  }
  return "";
}

static void emit(const char *mode, unsigned int util, unsigned int temp) {
  const char *cls;
  if (strcmp(mode, "temp") == 0) {
    cls = classify(temp, TEMP_WARN, TEMP_CRIT);
    printf("{\"text\":\"%s%u°C\",\"class\":\"%s\",\"tooltip\":\"GPU: %u%%  %u°C\"}\n", STRUT, temp, cls, util, temp);
  } else {
    cls = classify(util, UTIL_WARN, UTIL_CRIT);
    printf("{\"text\":\"%s%s %u%%\",\"class\":\"%s\",\"tooltip\":\"GPU: %u%%  %u°C\"}\n", STRUT, GPU_LABEL, util, cls, util, temp);
  }
  /* waybar reads this end of a pipe: an unflushed line is no line at all. */
  fflush(stdout);
}

static void emit_off(const char *reason) {
  printf("{\"text\":\"\",\"class\":\"off\",\"tooltip\":\"%s\"}\n", reason);
  fflush(stdout);
}

int main(int argc, char **argv) {
  const char *mode = "util";
  bool once = false;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-once") == 0 || strcmp(argv[i], "--once") == 0) {
      once = true;
    } else {
      mode = argv[i];
    }
  }
  if (strcmp(mode, "util") != 0 && strcmp(mode, "temp") != 0) {
    fprintf(stderr, "usage: gpu-watch <util|temp> [-once]\n");
    return 2;
  }

  if (!open_driver()) {
    emit_off("NVIDIA 驱动不可用");
    return 1;
  }

  /* Print before the first sleep: waybar shows nothing at all until a module
   * produces output. */
  do {
    unsigned int util, temp;
    if (!sample(&util, &temp)) {
      emit_off("NVIDIA 驱动无响应");
      return 1;
    }
    emit(mode, util, temp);
    if (!once) {
      struct timespec period = {.tv_sec = INTERVAL_MS / 1000,
                                .tv_nsec = (long)(INTERVAL_MS % 1000) * 1000000L};
      nanosleep(&period, NULL);
    }
  } while (!once);

  return 0;
}
