#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SENSOR_PATH "/sys/bus/iio/devices/iio:device0/in_temp_object_raw"

float read_temperature_celsius() {
    FILE *fp = fopen(SENSOR_PATH, "r");
    if (!fp) {
        perror("Failed to open sensor file");
        return -1000.0f;
    }

    int raw_value;
    if (fscanf(fp, "%d", &raw_value) != 1) {
        perror("Failed to read raw temperature");
        fclose(fp);
        return -1000.0f;
    }
    fclose(fp);

    float temp_c = raw_value * 0.02f - 273.15f;
    return temp_c;
}

int main() {
    while (1) {
        float temperature = read_temperature_celsius();
        if (temperature > -100) {
            printf("Temperatura: %.2f °C\n", temperature);
        } else {
            printf("Greska prilikom citanja temperature\n");
        }
        sleep(1);
    }
    return 0;
}
