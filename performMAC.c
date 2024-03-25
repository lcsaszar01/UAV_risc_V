#include <stdio.h>
// Function to perform MAC operations on two arrays
int performMAC(int* array1, int* array2, int length) {
    int accumulator = 0;
    for (int i = 0; i < length; i++) {
        accumulator += array1[i] * array2[i];
    }
    return accumulator;
}
int main() {
    // Example arrays
    int array1[] = {1, 2, 3, 4, 5};
    int array2[] = {10, 20, 30, 40, 50};
    int length = sizeof(array1) / sizeof(array1[0]);
    // Perform MAC operation
    int result = performMAC(array1, array2, length);
    // Print the result
    printf("The result of the MAC operation is: %d\n", result);
    return 0;
}