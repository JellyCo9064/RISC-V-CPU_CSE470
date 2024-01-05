int partition(int *array, int low, int high){
  // randomly chosen pivot
  int rand_pivot = low + (rand()%(high - low));
  int pivot;
  int i, j;

  // exchange chosen pivot with first element of array
  if(array[low] != array[rand_pivot]){
    array[low] ^= array[rand_pivot];
    array[rand_pivot] ^= array[low];
    array[low] ^= array[rand_pivot];
  }
  
  pivot = array[low];
  i = low + 1;
  for(j = i; j <= high; j++){
    if(array[j] < pivot){
      if(array[i] != array[j]){
        array[i] ^= array[j];
        array[j] ^= array[i];
        array[i] ^= array[j];
      }
      i++;
    }
  }

  if(array[low] != array[i-1]){
    array[low] ^= array[i-1];
    array[i-1] ^= array[low];
    array[low] ^= array[i-1];
  }
  return (i - 1);
}

void quicksort_rdaemon(int *array, int low, int high){
  if(low < high){
    int index;
    index = partition(array, low, high);
    quicksort_rdaemon(array, low, index - 1);
    quicksort_rdaemon(array, index + 1, high);
  }
}