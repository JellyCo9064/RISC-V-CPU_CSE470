void quicksort_helper(int *A, int len);
void quicksort(int arr[], int start, int end);

void quicksort_helper(int *A, int len) {
  if (len < 2) return;

  int pivot = A[len / 2];

  int i, j;
  for (i = 0, j = len - 1; ; i++, j--) {
    while (A[i] < pivot) i++;
    while (A[j] > pivot) j--;

    if (i >= j) break;

    int temp = A[i];
    A[i]     = A[j];
    A[j]     = temp;
  }

  quicksort_helper(A, i);
  quicksort_helper(A + i, len - i);
}

void quicksort_rosettacode(int arr[], int start, int end) {
  quicksort_helper(arr, end - start + 1);
}