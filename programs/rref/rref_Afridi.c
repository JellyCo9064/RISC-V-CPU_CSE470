#include<stdio.h>
#include<conio.h>
#include<math.h>
#define row 3
#define col 3

void main()
{
                float mat[row][col], ratio, shift = 0, det = 1, factor = 1, temp;
   int i, j, k, m, row_intrchng_count = 0;
   char c ='r';
while(c != 'q')
{             
   printf("Enter the matrix of order %dx%d", row, col );
   for(i = 0; i<row; i++)
                for(j = 0; j<col; j++)
                scanf("%f", &mat[i][j]);


   for(i = 0; i<row-1; i++)                                                 //for loop for gettting row echelon form of the matrix
   {
                for(j = i; j<col; j++)
      {
         if(j>i)
         {
                if(mat[i][i+shift] != 0)                   //mat[i][i+shift] is pivot element of the matrix
            {
                if(mat[j][i+shift] != 0)                //check whether the value is zero or needed to be made zero
               {


                               temp = mat[j][i+shift];
                               factor *= mat[i][i+shift];
                               for(k =0; k<col; k++)                                                                                                                        //elementary row operation of this loop does not change the value of the determinant
                               {
                                                                mat[j][k] *= mat[i][i+shift];
                               }
                                for(k =0; k<col; k++)                                                                                                                       //elementary row operation of this loop does not change the value of the determinant
                               {
                                                                mat[j][k] -= mat[i][k]*temp;
                               }
               }
                                }
            else
            {
                for(k = i+1; k<row; k++)
               if(mat[k][i] != 0)                                                                                                               //satisfaction of this condition means interchange of two rows and so determinant is multiplied by -1 per swapping of the two rows
                  {
                                row_intrchng_count++;
                     break;
                  }
               for(m = 0; m<col; m++)                                                                                  //this for loop interchange the two rows of the matrix
               {
               mat[i][m] = mat[i][m]+mat[k][m];
                  mat[k][m] = mat[i][m]-mat[k][m];
                  mat[i][m] = mat[i][m]-mat[k][m];
               }
               j--;                                           //to cancel the effect of the increment that take place after the end } of j loop
               if(k == row)    //this condition satisfaction means that matrix is singular
               {

                  mat[row-1][row-1] = 0;
                  i =row;
                  break;
               }

            }
         }
      }
   }

    if(mat[row-1][row-1] != 0)
    {
                for(i = 0; i<row; i++)
                det *= mat[i][i];
                det = pow(-1, row_intrchng_count)*det/factor;
    }
    else
                det = 0;
    printf("the determinant of the matrix = %f\n", det);

   for(i = 0; i<row; i++)
                for(j = 0; j<col; j++)
      {
                printf("%5.3f\t", mat[i][j]);
                if(j == (col-1))
                                printf("\n");
      }

   scanf("%c", &c);
}
   getch();
}
