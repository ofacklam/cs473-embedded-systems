int img_size = 1565;
uint img[] = {4582, 4, 315, 5, 314, 6, 314, 6, 315, 4, 317, 3, 636, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 2, 318, 2, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 2, 318, 1, 319, 2, 318, 2, 318, 2, 318, 2, 318, 2, 318, 2, 318, 2, 318, 2, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 2, 318, 2, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 1, 319, 2, 318, 2, 318, 2, 55, 2, 1, 4, 256, 2, 52, 4, 4, 7, 251, 2, 51, 3, 8, 5, 251, 2, 17, 7, 25, 2, 17, 3, 248, 1, 17, 3, 1, 3, 24, 2, 19, 4, 246, 1, 15, 2, 6, 3, 21, 3, 21, 4, 244, 1, 14, 2, 8, 3, 19, 3, 24, 3, 243, 1, 14, 2, 9, 3, 18, 2, 26, 4, 241, 1, 13, 2, 11, 3, 16, 2, 27, 4, 241, 1, 13, 1, 12, 3, 16, 2, 27, 4, 241, 1, 13, 1, 13, 3, 15, 1, 27, 5, 241, 1, 13, 1, 13, 3, 15, 1, 26, 4, 243, 1, 12, 1, 14, 7, 10, 2, 25, 3, 245, 1, 27, 19, 24, 3, 246, 1, 12, 1, 15, 4, 2, 2, 3, 8, 22, 2, 248, 1, 12, 1, 15, 3, 12, 9, 16, 3, 248, 1, 12, 1, 15, 3, 13, 2, 2, 7, 12, 2, 250, 2, 11, 1, 15, 3, 20, 7, 8, 3, 251, 1, 11, 1, 15, 3, 24, 5, 4, 3, 253, 1, 26, 4, 26, 4, 2, 4, 253, 1, 26, 3, 30, 6, 254, 1, 12, 1, 13, 3, 30, 5, 255, 1, 11, 3, 11, 4, 32, 4, 254, 2, 10, 3, 11, 4, 33, 3, 254, 2, 9, 4, 10, 5, 35, 2, 253, 2, 9, 5, 9, 4, 37, 2, 252, 2, 9, 1, 3, 3, 5, 5, 38, 2, 252, 2, 8, 2, 4, 4, 1, 6, 6, 8, 26, 2, 251, 2, 7, 2, 6, 10, 5, 11, 24, 8, 245, 2, 7, 2, 7, 8, 4, 15, 22, 9, 244, 2, 7, 1, 11, 1, 8, 1, 10, 6, 20, 3, 4, 3, 243, 2, 7, 1, 19, 3, 9, 2, 2, 3, 19, 3, 5, 3, 243, 1, 6, 1, 19, 4, 10, 1, 3, 4, 16, 2, 9, 2, 242, 1, 6, 1, 19, 4, 14, 5, 15, 2, 9, 2, 242, 1, 5, 2, 18, 12, 2, 2, 6, 4, 12, 2, 11, 2, 241, 1, 5, 2, 18, 18, 5, 3, 12, 1, 12, 2, 241, 1, 5, 1, 19, 19, 5, 4, 9, 1, 14, 1, 241, 1, 4, 2, 18, 20, 7, 3, 8, 1, 14, 1, 241, 1, 4, 1, 19, 22, 6, 3, 7, 1, 14, 2, 92, 2, 146, 1, 4, 1, 19, 24, 5, 3, 6, 1, 14, 2, 91, 3, 146, 2, 2, 2, 18, 26, 5, 2, 6, 1, 14, 2, 89, 5, 147, 1, 2, 2, 18, 27, 12, 1, 14, 2, 88, 2, 1, 3, 147, 1, 2, 1, 19, 28, 8, 1, 2, 2, 13, 1, 88, 2, 4, 2, 146, 1, 2, 1, 18, 32, 5, 2, 1, 2, 12, 2, 87, 2, 5, 3, 145, 1, 2, 1, 18, 33, 4, 5, 12, 2, 86, 3, 5, 3, 145, 1, 2, 1, 18, 34, 3, 6, 10, 2, 87, 2, 8, 1, 145, 1, 2, 1, 17, 36, 3, 5, 10, 2, 86, 2, 9, 1, 145, 4, 17, 36, 3, 6, 8, 2, 86, 2, 10, 1, 145, 4, 17, 36, 4, 7, 5, 3, 85, 2, 12, 3, 142, 4, 17, 37, 4, 3, 1, 9, 85, 2, 14, 3, 4, 2, 135, 4, 17, 37, 4, 3, 3, 5, 86, 3, 14, 10, 134, 3, 18, 38, 4, 1, 5, 3, 87, 2, 17, 4, 1, 3, 134, 3, 17, 40, 3, 1, 5, 3, 86, 3, 22, 2, 135, 3, 17, 40, 2, 2, 6, 1, 87, 2, 23, 2, 135, 3, 17, 41, 1, 2, 6, 1, 86, 2, 24, 2, 135, 3, 17, 44, 6, 1, 86, 2, 23, 2, 136, 3, 17, 44, 6, 1, 85, 2, 24, 2, 136, 4, 16, 43, 6, 2, 84, 2, 25, 3, 135, 4, 16, 42, 7, 1, 84, 3, 25, 4, 134, 4, 16, 41, 8, 1, 84, 2, 27, 3, 135, 3, 16, 40, 8, 2, 83, 2, 29, 2, 135, 3, 16, 39, 9, 2, 83, 2, 29, 2, 135, 4, 14, 40, 9, 2, 82, 2, 30, 2, 135, 4, 14, 39, 10, 2, 82, 1, 31, 2, 135, 4, 14, 38, 11, 2, 82, 1, 31, 2, 135, 4, 14, 37, 12, 2, 82, 1, 31, 2, 135, 4, 14, 36, 12, 3, 81, 1, 32, 2, 135, 4, 14, 35, 13, 2, 82, 1, 32, 2, 134, 5, 14, 35, 13, 2, 81, 2, 31, 2, 135, 5, 14, 34, 13, 3, 81, 2, 31, 2, 135, 5, 14, 33, 14, 2, 82, 2, 30, 2, 136, 5, 14, 33, 13, 3, 81, 2, 31, 2, 136, 6, 14, 31, 14, 2, 82, 2, 31, 1, 137, 6, 15, 29, 15, 2, 82, 2, 30, 2, 136, 7, 15, 29, 14, 2, 83, 1, 31, 2, 136, 7, 14, 29, 15, 2, 83, 1, 31, 1, 137, 7, 14, 29, 15, 2, 82, 1, 31, 2, 137, 7, 15, 28, 15, 2, 82, 1, 31, 2, 136, 9, 14, 28, 14, 2, 83, 1, 31, 1, 137, 9, 14, 28, 14, 2, 83, 1, 30, 2, 137, 9, 15, 27, 13, 3, 83, 1, 30, 2, 137, 10, 15, 26, 12, 3, 84, 1, 29, 2, 138, 10, 15, 26, 12, 3, 84, 1, 29, 2, 137, 11, 15, 26, 12, 3, 84, 1, 28, 2, 138, 12, 11, 1, 3, 25, 11, 3, 85, 1, 28, 1, 139, 12, 10, 3, 3, 24, 11, 3, 85, 2, 26, 2, 139, 12, 11, 3, 2, 24, 11, 4, 85, 1, 25, 2, 140, 12, 12, 2, 3, 23, 11, 4, 111, 2, 139, 14, 11, 2, 4, 22, 11, 6, 108, 2, 140, 14, 12, 2, 4, 17, 2, 1, 11, 2, 3, 3, 83, 2, 22, 2, 140, 14, 12, 2, 5, 15, 3, 1, 11, 2, 5, 2, 82, 3, 21, 1, 141, 15, 12, 2, 5, 11, 2, 1, 15, 1, 7, 2, 80, 7, 17, 2, 141, 15, 12, 3, 5, 9, 3, 3, 12, 2, 9, 2, 78, 12, 10, 3, 142, 15, 13, 2, 8, 6, 3, 2, 13, 2, 9, 2, 77, 14, 8, 3, 142, 17, 13, 3, 1, 14, 14, 2, 12, 2, 74, 14, 154, 17, 13, 17, 15, 2, 13, 2, 73, 11, 157, 17, 18, 11, 15, 3, 14, 3, 70, 11, 158, 18, 20, 6, 17, 2, 16, 3, 68, 12, 157, 19, 43, 2, 18, 2, 67, 11, 158, 19, 42, 3, 18, 3, 66, 11, 158, 20, 41, 2, 21, 2, 64, 11, 159, 20, 40, 3, 22, 2, 63, 11, 159, 21, 39, 2, 24, 2, 61, 11, 160, 22, 37, 3, 86, 11, 161, 24, 34, 3, 28, 2, 56, 12, 160, 26, 32, 4, 28, 3, 55, 11, 161, 27, 30, 4, 31, 1, 54, 12, 161, 28, 28, 5, 32, 2, 52, 11, 162, 30, 25, 5, 34, 2, 50, 11, 163, 32, 21, 7, 36, 1, 49, 11, 163, 33, 18, 9, 36, 2, 47, 11, 164, 35, 12, 13, 37, 2, 45, 12, 163, 61, 39, 2, 43, 11, 164, 60, 40, 3, 41, 11, 165, 60, 42, 2, 40, 11, 165, 60, 43, 2, 38, 11, 166, 59, 45, 2, 37, 10, 166, 60, 46, 2, 35, 11, 166, 60, 47, 3, 32, 12, 166, 60, 48, 3, 31, 11, 167, 59, 50, 3, 29, 11, 168, 59, 52, 2, 28, 11, 167, 60, 52, 3, 26, 11, 168, 59, 55, 3, 23, 12, 168, 59, 56, 2, 23, 11, 169, 59, 57, 3, 20, 11, 170, 59, 58, 3, 19, 11, 169, 59, 60, 3, 17, 11, 170, 59, 61, 3, 16, 11, 170, 59, 63, 3, 13, 11, 171, 58, 65, 2, 13, 11, 171, 58, 66, 3, 10, 11, 172, 58, 67, 2, 9, 11, 173, 58, 68, 3, 7, 11, 172, 59, 69, 3, 6, 10, 173, 58, 71, 3, 4, 11, 173, 58, 73, 2, 2, 11, 174, 58, 74, 14, 174, 58, 74, 13, 175, 58, 75, 11, 176, 57, 76, 11, 175, 58, 76, 10, 176, 58, 75, 11, 176, 58, 74, 11, 177, 58, 74, 11, 177, 57, 74, 12, 177, 57, 73, 12, 178, 57, 73, 11, 179, 57, 72, 11, 180, 57, 72, 11, 180, 57, 71, 11, 180, 58, 70, 11, 181, 58, 70, 11, 181, 58, 69, 12, 181, 58, 69, 11, 182, 58, 68, 11, 183, 58, 67, 12, 183, 58, 67, 11, 184, 58, 66, 11, 185, 58, 66, 11, 185, 58, 65, 11, 186, 58, 64, 12, 187, 57, 64, 11, 187, 59, 62, 12, 93};
