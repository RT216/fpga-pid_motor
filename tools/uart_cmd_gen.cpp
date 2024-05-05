#if __cplusplus <= 199711L
#error This program requires a compiler supporting at least C++ 11
#endif

#include <cstddef>
#include <cstdio>
#include <iostream>
#include <sstream>
#include <string>
#include <unistd.h>
#include <utility>
#include <vector>

using namespace std;

int rpm2command(int rpm, int chn) {
    if(rpm > 0)
        return rpm + chn * 8192;
    else
        return 8192 + rpm + chn * 8192;
}
int int2bin(int n) {
    int retval = 0;
    int i = 1;
    while (n > 0) {
        retval += (n % 2) * i;
        n /= 2;
        i *= 10;
    }
    return retval;
}

int main() {
    int retval = 0;
    char c;
    do
    {
        cout << "Enter the target rpm value (-4096~4095) ";
    
        int target_rpm[4];
        for (int i = 0; i < 4; i++) {
            cin >> target_rpm[i];
        }

        printf("The command is: \n");
        printf("1. \t1001_0001\t0x91\t\"set_rpm\"\n");
        for (int i = 0; i < 4; i++) {
            int v1 = rpm2command(target_rpm[i], i) / 256;
            int v2 = rpm2command(target_rpm[i], i) % 256;
            printf("%d.1\t%04d_%04d\t0x%02X\t\"chn = %d\"\n", i, int2bin(v1/16), int2bin(v1%16), v1, i);
            printf("%d.2\t%04d_%04d\t0x%02X\t\"rpm = %d\"\n", i, int2bin(v2/16), int2bin(v2%16), v2, target_rpm[i]);
        }
        printf("4. \t1111_1111\t0xFF\t\"return\"\n");

        cout << endl;
        cout << "Do you want to continue? (y/n) ";
        cin >> c;
    } while (c == 'y' || c == 'Y');
    


    
    return retval;
}
