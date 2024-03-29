void quicksort_hackrc(int number[], int first, int last);

void quicksort_hackrc(int number[],int first,int last){

    int i, j, pivot, temp;

    if (first<last) {
        pivot=first;
        i=first;
        j=last;

        while (i<j) {

            while (number[i]<=number[pivot]&&i<last)
                i++;

            while(number[j]>number[pivot])
                j--;

            if (i<j) {
                temp=number[i];
                number[i]=number[j];
                number[j]=temp;
            }

        }

        temp=number[pivot];
        number[pivot]=number[j];
        number[j]=temp;

        quicksort_hackrc(number, first, j-1);
        quicksort_hackrc(number, j+1, last);

    }

}