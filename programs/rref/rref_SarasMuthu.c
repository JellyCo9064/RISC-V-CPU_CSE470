#include <stdio.h>
  #include <stdlib.h>
   int main()
  {
  //Assumptions, c >= n-k . And k = n/2  , ie half rate codes
 
   int i,j,sum=0,k,r2,j2,i2;
 
   int r,c,n;
   int temp=0;
  k = 3;
  r = 3;
  c = 6;
  n = 6;
  int msg[3] = {0,1,1};
  int H[3][6] = {1,1,0,0,1,0,1,0,0,1,0,1,1,1,1,0,0,1};
  printf("H Matrix is: \n\n");
  for(i=0;i<r;i++)
    {
       for(j=0;j<c;j++)
       printf("%d\t",H[i][j]);
       printf("\n");
   }
   for(i=0;i<n-k;i++)  
  {
     j=n-k+i;  
     if(H[i][j] != 1) 
        {
            for(i2=i+1;i2<r;i2++)
            {
                if(H[i2][j] == 1) 
                {
                    for(j2=0;j2<c;j2++)  
                    {
                        temp = H[i2][j2];
                        H[i2][j2] = H[i][j2];
                        H[i][j2] = temp;
                    }
                    break;
                }
                if(i2 == r-1)
                    printf("\nERROR..!! The whole of column %d has NO 1(at row %d)",j+1,i+1);
            }
        }
        for(i2 = 0;i2<r;i2++)  
        {
            if(i2 != i && H[i2][j] == 1) 
                {
                    for(j2=0;j2<c;j2++)  
                    {
                        H[i2][j2] = abs(H[i][j2] - H[i2][j2]); 
                    }
                }
        }
}
       printf("\nH Matrix in different form is: \n\n");
      for(i=0;i<r;i++)
  {
        for(j=0;j<c;j++)
        printf("%d\t",H[i][j]);
        printf("\n");
  }
 
  printf("\n\nGenerator Matrix\n\n");
 int G[10][10] = {0};
  for (i=0;i<k;i++)
   for(j=0;j<k;j++)
        if(i == j)
        G[i][j] = 1;
 
     for(i=0;i<r;i++)
     for(j=0;j<k;j++)
        G[j][k+i] = H[i][j];
 
    for(i=0;i<r;i++)
   {
        for(j=0;j<c;j++)
        printf("%d\t",G[i][j]);
      printf("\n");
  }
 
  //Code word generation
   int C[10];
    int s = 0;
   for(j=0;j<n;j++)
    {
    for(i=0;i<k;i++)
    {
        s = s+msg[i]*G[i][j];
    }
    C[j] = s%2;
    s = 0;
   }
     printf("\n\nCode Word is: \n\n");
    for(i=0;i<n;i++)
    printf("%d\t",C[i]);
  }