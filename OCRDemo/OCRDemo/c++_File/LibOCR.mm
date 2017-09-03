#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#import "LibOCR.h"
#import "string.h"
#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
    extern void saveLetterPos(int *pos);    //save the positions of letters to the program(implemeted in Objective-c file, which can be found in runtime)
    extern void saveNumPos(int *pos);       //save the positions of id card numbers to the program(implemeted in Objective-c file, which can be found in runtime)
#ifdef __cplusplus
}
#endif

typedef unsigned char  uc;
typedef struct _Variance{
    int va;
    int height;
    float ang;
    int oldva;
} Varivance;
typedef enum{
    LibScanIDCard,
    LibScanPassport
}LibScanType;

extern int byteOneCount[256];
extern char templateImage[36][200][25];
extern int charTemplateCount[36];

static int cmpVarianceIDCard(const void* a,const void* b){
    return (( Varivance *)b)->va-((Varivance *)a)->va;
}
int cmpHeight(const void* a,const void* b){
    return ((Varivance*)a)->height-((Varivance*)b)->height;
}
static void generateBlackImage(int oldwidth,int oldheight,uc **grayimage,uc **blackimage){
    uc *thre;
    thre = (uc*)malloc(sizeof(uc) * ((int)oldwidth / 100));
    memset(thre, 0, ((int)oldwidth / 100));
    uc means1 = 0;
    uc means2 = 0;
    int sub1 = 0;
    int sub2 = 0;
    int sub1count = 0;
    int sub2count = 0;
    for(int i = 0;i<(int)(oldwidth/100);i++){
        uc finalthre = 0;
        uc inithreshold = 40;
        while(finalthre!=inithreshold){
            finalthre = inithreshold;
            sub1 = sub1count = sub2 = sub2count = 0;
            for(int j = 0;j<(oldheight*100);j++){
                uc pixtmp = grayimage[j/100][i*100+j%100];
                if(pixtmp<=inithreshold){
                    sub1+=pixtmp;
                    sub1count++;
                }else{
                    sub2+=pixtmp;
                    sub2count++;
                }
            }
            means1 = sub1count==0? inithreshold:sub1/sub1count;
            means2 = sub2count==0? inithreshold:sub2/sub2count;
            inithreshold = (means1+means2)/2;
            if(((float)sub2count/sub1count)<8&&inithreshold>finalthre){
                break;
            }
        }
        thre[i] = finalthre;
    }
    for(int i =0;i<oldheight;i++){
        uc tmp = 0;
        uc tmpbyte = 0;
        for(int j = 0;j<oldwidth;j++){
            if(grayimage[i][j]<thre[j/100]){
                tmpbyte = (tmpbyte<<1)+1;
            }else{
                tmpbyte=tmpbyte<<1;
            }
            
            tmp++;
            if(tmp == 8){
                blackimage[i][j/8] = tmpbyte;
                tmp = 0;
                tmpbyte = 0;
            }
        }
        
        blackimage[i][oldwidth/8] = tmpbyte<<4;
    }
    free(thre);
}
static int getVariance(int oldwidth,int oldheight,uc **blackimage,float ang,int height){
    int result = 0;
    for(int i = 0;i<oldwidth;i+=8){
        int h = (int)round(i*ang)+height;
        if(h<0||h>=oldheight) break;
        int wid = i/8;
        uc tmp = ((blackimage[h][wid]>>1)^(blackimage[h][wid]))&0x7f;
        result += byteOneCount[tmp];
        if((blackimage[h][wid]&1) != ((blackimage[h][wid+1]&0x80)>>7)){
            result++;
        }
    }
    return result;
}
static int getMeans(int* a,int count){
    int total = 0;
    for(int i = 0;i<count;i++){
        total += a[i];
    }
    return (int)roundf((float)total/count);
}
//ps: specified for id card
static bool checkIntIDCard(int oldwidth,int oldheight,uc **blackimage,int* a,float ang){
    float d1;//, d2, d3;
    d1 = a[1] - a[0];
    float width = d1 / 3;
    for (int j = 1; j < 3; j++) {
        //        int temp=getVarianceIDCard(oldwidth,oldheight,blackimage,ang, roundf(a[0]+j*width));
        if (getVariance(oldwidth,oldheight,blackimage,ang, roundf(a[0]+j*width)) < 20) {
            return false;
        }
    }
    return true;
}

static bool checkIntPassport(int oldwidth,int oldheight,uc **blackimage,int* a,float ang){
    float d1, d2, d3;
    d1 = a[1] - a[0];
    d2 = a[2] - a[1];
    d3 = a[3] - a[2];
    if (d1 / d3 > 1.4 || d1 / d3 < 0.7) {
        return false;
    }
    if (d2 / ((d1 + d3) / 2) < 1 || d2 / ((d1 + d3) / 2) > 1.8) {
        return false;
    }
    float width = d2 * 0.5;// willard 检测中间 白条 宽度 为0.5
    float diff = width/5;
    for (float j = -width / 2; j < width / 2; j += diff) {
        if(getVariance(oldwidth,oldheight,blackimage,ang, roundf(((float)(a[2]+a[1]))/2+j))>15){
            return false;
        }
    }
    width = d1 / 3;
    for (int j = 1; j < 3; j++) {
        //        int var = variance(blackImage, peak.get(i) + j * width, angle);
        if (getVariance(oldwidth,oldheight,blackimage,ang, roundf(a[0]+j*width)) < 80) {
            return false;
        }
    }
    width = d3 / 3;
    for (int j = 1; j < 3; j++) {
        //        int var = variance(blackImage, peak.get(i + 2) + j * width, angle);
        if (getVariance(oldwidth,oldheight,blackimage,ang, roundf(a[2]+j*width)) < 80) {
            return false;
        }
    }
    return true;
}


static bool getHeightEdge(int oldwidth,int oldheight,uc **blackimage,int bWidth,int bHeight,float* angle,int* heightEdge,LibScanType type){//100*51
    if(oldwidth<=0)
        return false;
    if(oldheight<=0)
        return false;
    Varivance varivances[5][bHeight];//passport variance original size is 135, not 131
    struct VarivanceNode {
        struct VarivanceNode *next;
        struct VarivanceNode *before;
        float ang;
        int va;
    };
    struct VarivanceNode *head = NULL;
    struct VarivanceNode *tail = NULL;
    int maxva = 0, minva = 0xfffff;
    int count = 0;
    struct VarivanceNode nodes[5*bHeight];
    int nodescount = 0;
    for (int i = -2; i <= 2; i++) {
        for (int j = 0; j < oldheight; j++) {
            float ii = (float) i / 100;
            int varivance = getVariance(oldwidth, oldheight, blackimage, ii, j);
            if (j <= 5) {
                Varivance v = {0, 0, 0, varivance};
                varivances[i + 2][j] = v;
            } else {
                Varivance v = {abs(varivance - varivances[i + 2][j - 6].oldva), j - 3, ii, varivance};
                varivances[i + 2][j] = v;
                if (v.va > minva || count < 10) {
                    struct VarivanceNode *node = &(nodes[nodescount++]);
                    node->ang = ii;
                    node->va = v.va;
                    node->next = NULL;
                    node->before = NULL;
                    if (count < 10) {
                        if (count == 0) {
                            maxva = minva = v.va;
                            head = node;
                            tail = node;
                        } else {
                            if (maxva <= v.va) {
                                maxva = v.va;
                                node->next = head;
                                head->before = node;
                                head = node;
                            } else if (minva > v.va) {
                                minva = v.va;
                                node->before = tail;
                                tail->next = node;
                                tail = node;
                            }else {
                                for (node->next = head; node->va <
                                     node->next->va; node->next = node->next->next) { }
                                node->before = node->next->before;
                                node->before->next = node;
                                node->next->before = node;
                            }
                        }
                        count++;
                    } else {
                        node->next = head;
                        for (; node->va < node->next->va; node->next = node->next->next) { }
                        if (node->next != head) {
                            node->before = node->next->before;
                            node->before->next = node;
                        } else {
                            head = node;
                        }
                        node->next->before = node;
                        tail = tail->before;
                        minva = tail->va;
                        tail->next = NULL;
                    }
                }
            }
        }
    }
    float countva = 0;
    count = 0;
    for (; ;) {
        count++;
        if (head != NULL&&head->ang==head->ang) {
            countva += head->ang;
            if (head->next != NULL) {
                head = head->next;
            } else {
                head = NULL;
                break;
            }
        }
    }
    int ang = (int) roundf(countva *= 10) + 2;
    *angle = (float) (ang - 2) / 100;
    Varivance *v = varivances[ang];
    qsort(v, oldheight, sizeof(Varivance), cmpVarianceIDCard);
    qsort(v, 24, sizeof(Varivance), cmpHeight);
    int heights[24];
    count = 0;
    int peaks[24] = {0};
    int peaknum = 0;
    for (int i = 0; i < 24; i++) {
        int h = v[i].height;
        if (count == 0) {
            heights[count++] = h;
        } else if (heights[count - 1] + 3 < h) {
            peaks[peaknum++] = getMeans(heights, count);
            count = 1;
            heights[0] = h;
        } else {
            heights[count++] = h;
        }
    }
    if (count > 1) {
        peaks[peaknum++] = getMeans(heights, count);
    }
    //筛选peak
    switch (type) {
        case LibScanIDCard:
            for (int i = 0; i < peaknum - 1; i++) {
                if (checkIntIDCard(oldwidth, oldheight, blackimage, &(peaks[0]), *angle)) {
                    heightEdge[0] = peaks[0];
                    heightEdge[1] = peaks[1];
                    return true;
                }
            }
            break;
        case LibScanPassport:
            for(int i = 0;i<peaknum-3;i++){
                if(checkIntPassport(oldwidth,oldheight,blackimage,&(peaks[i]),*angle)){
                    heightEdge[0] = peaks[i];
                    heightEdge[1] = peaks[i+1];
                    heightEdge[2] = peaks[i+2];
                    heightEdge[3] = peaks[i+3];
                    return true;
                }
            }
        default:
            break;
    }
    return false;
}
static uc getPixelByBlackImage(uc **blackImage,int x,int y){
    if (x < 0 || y < 0) {
        return 0;
    }
    return (blackImage[y][x/8]>>(7-x%8))&1;
}

static bool generateLetterXPassport(int up,int down,uc **blackImage,float angle,int width,int height,int result[130],int* spaces){
    //    LOGE("%d",blackimage[83][13]);
    int x12[120][2] = {0};
    uc count = 0;
    uc d = (down-up)/3;
    up = up-d<0?0:up-d;
    down = down+d>height?height:down+d;
    int lastWhite = -1;
    for(int i =0;i<width;i++){
        int isWhite = 0;
        int startY = (int)(down+angle*i);
        startY = startY>=height?height-1:startY;
        for (int j = 0; j < down - up; j++) {
            if (startY - j >= height || i + (j * angle) >= width || i + (j * angle) < 0 ) { //                if (i + (j * angle) < 0 || i + (j * angle) >= width) {//different judgement
                continue;
            }
            uc rgb = getPixelByBlackImage(blackImage, (i + (j * angle)), startY - j);
            if(rgb != 0){
                isWhite += 1;
                if (isWhite >= 2) {//willard
                    break;
                }
            }
        }
        if (isWhite > 1) {
            if (lastWhite != -1) {
                if (i - lastWhite == 1) {// 忽略字符中间的断裂
                    lastWhite = -1;
                    continue;
                }
                x12[count][0] = lastWhite;
                x12[count++][1] = i-lastWhite;
                lastWhite = -1;
            }
        } else {
            if (lastWhite == -1) {
                lastWhite = i;
                // todo 优化i的值
                if(count!=0&&x12[count-1][0]+x12[count-1][1]>=i-2){
                    lastWhite = x12[count-1][0];
                    //                    lastWhite = fourInts.get(fourInts.size() - 1).a;
                    count--;
                }
            }
        }
    }
    if (lastWhite != -1) {
        x12[count][0] = lastWhite;
        x12[count++][1] = width+1-lastWhite;
        //        fourInts.add(new FourInt().setA(lastWhite).setB(blackImage.getWidth() + 1 - lastWhite));
    }
    //    for(int i = 0;i<count;i++){
    //            cout<<(int)(x12[i][0])<<"__"<<(int)(x12[i][1])<<endl;
    //            LOGE("%d_%d",x12[i][0],x12[i][1]);
    //    }
    //        LOGE("*******");
    if (count < 30) {
        printf("空格数小于30");
        return false;
    }
    int resultcount  = 0;
    // result.add(fourInts.get(0).a == 0 ? fourInts.get(0).b - 1 + fourInts.get(0).a : -1);
    if(x12[0][0] == 0){
        result[resultcount++] = x12[0][1]-1;
        //        result.add(fourInts.get(0).b - 1 + fourInts.get(0).a);
    } else {
        result[resultcount++] = 0;
        result[resultcount++] = x12[0][0];
        if(result[1]-result[0]<4||result[1]-result[0]>(float)width/43){
            resultcount = 0;
        }
        result[resultcount++] = x12[0][1]+x12[0][0]-1;
    }
    int maxWidth =  width/ 43;
    for (int i = 1; i < count; i++) {
        //        if (fourInts.get(i).b > maxWidth) {
        if(x12[i][1]>maxWidth){
            if (resultcount > 60) {
                //                result.add(fourInts.get(i).a);
                result[resultcount++] = x12[i][0];
                break;
            }
            resultcount = 0;
            //            if (fourInts.size() - i + 1 < 30) {
            if(count-i+1<30){
                printf("空格数小于43");
                //                    cout<<"空格数小于30"<<endl;
                return false;
            }
            //            result.add(fourInts.get(i).a + fourInts.get(i).b - 1);
            result[resultcount++] = x12[i][0]+x12[i][1]-1;
        } else {
            //            if (fourInts.get(i).a - result.get(result.size() - 1) > (double) blackImage.getWidth() / 43d) {
            if(x12[i][0]-result[resultcount-1]>(float)width/43){
                //                System.out.println(fourInts.get(i).a - result.get(result.size() - 1));
                //                System.out.println((double) blackImage.getWidth() / 43d * 0.8);
                printf("字符过长.........失败");
                return false;
            }
            result[resultcount++] = x12[i][0];
            if(i!=count-1){
                result[resultcount++] = x12[i][0]+x12[i][1]-1;
            }
        }
    }
    //    for(int i = 0;i<resultcount;i++){
    //            cout<<result[i]<<endl;
    //            LOGE("%d",result[i]);
    //    }
    if(resultcount < 88){
        printf("字符数不对 count = %d\n",resultcount);
        printf("白格数过少,最少88个, count = %d\n",resultcount);
        return false;
    }
    *spaces = resultcount;
    return true;
}

//ps: different
static bool generateLetterXIDCard(int up,int down,uc **blackimage,float angle,int width,int height,int result[130],int* spaces){
    int x12[120][2] = {0};
    uc count = 0;
    uc d = (down-up)/3;
    up = up-d<0?0:up-d;
    down = down+d>height?height:down+d;
    int lastWhite = -1;
    for(int i =0;i<width;i++){
        int isWhite = 0;
        int startY = (int)(down+angle*i);
        startY = startY>=height?height-1:startY;
        for (int j = 0; j < down - up; j++) {
            if (startY - j >= height || i + (j * angle) >= width) {
                continue;
            }
            uc rgb = getPixelByBlackImage(blackimage, (i + (j * angle)), startY - j);
            if(rgb != 0){
                isWhite += 1;
                if (isWhite >= 2) {
                    break;
                }
            }
        }
        if (isWhite > 1) {
            if (lastWhite != -1) {
                if (i - lastWhite == 1) {
                    lastWhite = -1;
                    continue;
                }
                x12[count][0] = lastWhite;
                x12[count++][1] = i-lastWhite;
                lastWhite = -1;
            }
        } else {
            if (lastWhite == -1) {
                lastWhite = i;
                if(count!=0&&x12[count-1][0]+x12[count-1][1]>=i-2){
                    lastWhite = x12[count-1][0];
                    count--;
                }
            }
        }
    }
    if (lastWhite != -1) {
        x12[count][0] = lastWhite;
        x12[count++][1] = width+1-lastWhite;
    }
    if (count < 17) {
        return false;
    }
    int resultcount  = 0;
    if(x12[0][0] == 0){
        result[resultcount++] = x12[0][1]-1;
    } else {
        result[resultcount++] = 0;
        result[resultcount++] = x12[0][0];
        result[resultcount++] = x12[0][1]+x12[0][0]-1;
    }
    int maxWidth =  width/ 17;
    for (int i = 1; i < count; i++) {
        if(x12[i][1]>maxWidth){
            if (resultcount > 19) {
                result[resultcount++] = x12[i][0];
                break;
            }
            resultcount = 0;
            result[resultcount++] = x12[i][0]+x12[i][1]-1;
        } else {
            if(x12[i][0]-result[resultcount-1]>(float)width/17){
                return false;
            }
            result[resultcount++] = x12[i][0];
            if(i!=count-1){
                result[resultcount++] = x12[i][0]+x12[i][1]-1;
            }
        }
    }
    if(resultcount < 18){
        return false;
    }
    *spaces = resultcount;
    return true;
}

static int checkWhite(uc **blackImage,int x1,int x2,int y){
    int count = 0;
    for (int i = 0; i < x2 - x1 + 1; i++) {
        if(getPixelByBlackImage(blackImage, x1+i, y) != 0){
            count++;
            if (count > 3) {
                return count;
            }
        }
    }
    return count;
}
static void expandFourInt(int letterEdge[4],uc **blackImage,int width,int height){
    int flag = -1;
    while (flag != 0) {
        if (flag < 0) {
            if (checkWhite(blackImage, letterEdge[0], letterEdge[2], letterEdge[1] - 1) >= 2) {
                letterEdge[1]+=flag;
                if (letterEdge[1]== 0) {
                    flag = 0;
                }
            } else {
                flag = 1;
            }
        } else {
            if (checkWhite(blackImage, letterEdge[0], letterEdge[2], letterEdge[1]) < 2) {
                letterEdge[1] += flag;
                if (letterEdge[1] == height - 1 || letterEdge[1] == letterEdge[3] - 3) {
                    flag = 0;
                }
            } else {
                flag = 0;
            }
        }
    }
    flag = 1;
    while (flag != 0) {
        if (flag > 0) {
            if (checkWhite(blackImage, letterEdge[0], letterEdge[2], letterEdge[3] + 1) >= 2) {
                letterEdge[3]+= flag;
                if (letterEdge[3] == height - 1) {
                    flag = 0;
                }
            } else {
                flag = -1;
            }
        } else {
            if (checkWhite(blackImage, letterEdge[0], letterEdge[2], letterEdge[3]) < 2) {
                letterEdge[3] += flag;
                if (letterEdge[3] == 0 || letterEdge[3] == letterEdge[1] + 2) {
                    flag = 0;
                }
            } else {
                flag = 0;
            }
        }
    }
}

static bool getLettersXYPassport(int **letters,int upLetterX[130],int downLetterX[130],int heightedge[4],uc **blackImage,float angle,int width,int height,int upspaces,int downspaces){
    int count = 0;
    int leftX = -1;
    int diff;
    for (int i = 0; i < upspaces; i++) {
        if (count >= 88) {
            return false;
        }
        if (leftX == -1) {
            leftX = upLetterX[i];
            continue;
        }
        //        FourInt fourInt = new FourInt().setA(leftX + 1).setB(heightEdge.a).setC(upLetterX.get(i) - 1).setD(heightEdge.b);
        diff = angle*(leftX+1);
        int letterEdge[4] = {leftX+1,heightedge[0]+diff,upLetterX[i]-1,heightedge[1]+diff};
        expandFourInt(letterEdge, blackImage,width,height);
        //        if (fourInt.d - fourInt.b + 1 > (heightEdge.b - heightEdge.a + 1) * 0.7 && fourInt.d - fourInt.b + 1 < (heightEdge.b - heightEdge.a + 1) * 1.25) {
        if(letterEdge[3]-letterEdge[1]+1>(heightedge[1]-heightedge[0]+1)*0.6&&letterEdge[3]-letterEdge[1]+1<(heightedge[1]-heightedge[0]+1)*1.35){//todo willard
            //            letters.add(fourInt);
            letters[count][0] = letterEdge[0];
            letters[count][1] = letterEdge[1];
            letters[count][2] = letterEdge[2];
            letters[count++][3] = letterEdge[3];
        }
        leftX = -1;
    }
    if(count != 44) return false;
    leftX = -1;
    for (int i = 0; i < downspaces; i++) {
        if (count >= 88) {
            return false;
        }
        if (leftX == -1) {
            leftX = downLetterX[i];
            continue;
        }
        //        FourInt fourInt = new FourInt().setA(leftX + 1).setB(heightEdge.c).setC(downLetterX.get(i) - 1).setD(heightEdge.d);
        diff = angle*(leftX+1);
//        
//        //fix crash
//        if (heightedge[3]+diff >= 134) {
//            return false;
//        }
//        
        int letterEdge[4] = {leftX+1,heightedge[2]+diff,downLetterX[i]-1,heightedge[3]+diff};
        expandFourInt(letterEdge, blackImage,width,height);
        //        if (fourInt.d - fourInt.b + 1 > (heightEdge.d - heightEdge.c + 1) * 0.8 && fourInt.d - fourInt.b + 1 < (heightEdge.d - heightEdge.c + 1) * 1.15) {
        if(letterEdge[3]-letterEdge[1]+1>(heightedge[3]-heightedge[2]+1)*0.6&&letterEdge[3]-letterEdge[1]+1<(heightedge[3]-heightedge[2]+1)*1.35){//todo willard
            //            letters.add(fourInt);
            letters[count][0] = letterEdge[0];
            letters[count][1] = letterEdge[1];
            letters[count][2] = letterEdge[2];
            letters[count++][3] = letterEdge[3];
        }
        leftX = -1;
    }
    if(count != 88) return false;
    return true;
}

//PS: different
static bool getLettersXYIDCard(int **letters,int upletterX[130],int heightedge[2],uc **blackImage,float angle,int width,int height,int upspaces){
    int count = 0;
    int leftX = -1;
    int diff;
    for (int i = 0; i < upspaces; i++) {
        if (count >= 18) {
            return false;
        }
        if (leftX == -1) {
            leftX = upletterX[i];
            continue;
        }
        diff = angle*(leftX+1);
        int letteredge[4] = {leftX+1,heightedge[0]+diff,upletterX[i]-1,heightedge[1]+diff};
        expandFourInt(letteredge, blackImage,width,height);
        if(letteredge[3]-letteredge[1]+1>(heightedge[1]-heightedge[0]+1)*0.6&&letteredge[3]-letteredge[1]+1<(heightedge[1]-heightedge[0]+1)*1.35){
            letters[count][0] = letteredge[0];
            letters[count][1] = letteredge[1];
            letters[count][2] = letteredge[2];
            letters[count++][3] = letteredge[3];
        }
        leftX = -1;
    }
    if (count != 18) {
        return false;
    }
    return true;
}
static char getCharByIntIDCard(int maxI){
    if (maxI < 10) {
        char a = 48+maxI;
        return a;
    }
    return 'X';
}
static char getCharByIntPassport(int maxI){
    if (maxI < 10) {
        char a = 48+maxI;
        return a;
    } else if (maxI == 31) {
        return '<';
    }
    return (char) (55 + maxI);
}
void static ocr(uc **letterImage,int letterNum,char* result,int* iaa,LibScanType type) {
    int min = 0xfffff;
    int answer = 0;
    for(int m = 0;m<letterNum;m++){
        answer = 0;
        min = 0xfffff;
        for(int k = 0;k<36;k++){
            for(int l =0;l<charTemplateCount[k];l++){
                int relations = 0;
                for(int i = 0;i<25;i++){
                    uc r =letterImage[m][i]^templateImage[k][l][i];
                    relations += byteOneCount[r];
                }
                if(relations<min){
                    min = relations;
                    answer = k;
                }
            }
        }
        switch (type) {
            case LibScanPassport:
                result[m] = getCharByIntPassport(answer);
                break;
            case LibScanIDCard:
                result[m] = getCharByIntIDCard(answer);
            default:
                break;
        }
    }
}

//check the validity of id card scan result
static bool checkValue(char* result) {
    //region  check null
    for(int i=0;i<18;i++){
        if(!result[i] || result[i]==' ' || (result[i] == 'X' && i < 17)){
            return false;
        }
    }
    //endregion
    //region //first
    if(result[0]<'1'||result[0]>'9'){
        return false;
    }
    //endregion
    //region //y
    if(result[6]!='1'&&result[6]!='2'){
        return false;
    }
    //endregion
    //region //m
    if(result[10]!='0'&&result[10]!='1'){
        return false;
    }
    //endregion
    //region //d
    if(result[12]!='0'&&result[12]!='1'&&result[12]!='2'&&result[12]!='3'){
        return false;
    }
    //endregion
    return true;
}

static void divideChar(uc **blackImage,int **lettersXY,uc **letterImage,int letterNum,int imageWidth,int imageHeight){
    int width,height;
    uc **image;//[100][407] = {0};
    image = (uc**)malloc(sizeof(uc*)*imageHeight);
    *image = (uc*)malloc(sizeof(**image) * imageWidth * imageHeight);
    for (int i = 1; i < imageHeight; i++) {
        image[i] = *image + imageWidth * i;
    }
    for(int i = 0;i<letterNum;i++){
        width = lettersXY[i][2]-lettersXY[i][0]+1;
        height = lettersXY[i][3]-lettersXY[i][1]+1;
        memset(*image, 0, imageHeight * imageWidth);
        for(int j = 0;j<height;j++){
            for(int k = 0;k<width;k++){
                if (j + lettersXY[i][1] >= imageHeight || k+lettersXY[i][0] >= imageWidth) {
                    continue;
                }
                char a = getPixelByBlackImage(blackImage, k+lettersXY[i][0], j+lettersXY[i][1]);
                image[j][k] = a;
            }
        }
        float pixelwidth = (float)width/13;
        float pixelheight = (float)height/15;
        int flag = 0;
        int count = 0;
        for(int j = 0;j<15;j++){
            for(int k = 0;k<13;k++){
                float startx = k*pixelwidth;
                float starty = j*pixelheight;
                float endx = startx+pixelwidth;
                float endy = starty+pixelheight;
                float color = 0;
                for(int m = (int) starty;m<=(int)endy;m++){
                    if(m == height){
                        break;
                    }
                    float d;
                    
                    if(m == (int)starty){
                        if(m == (int)endy){
                            d = endy-starty;
                        }else{
                            d = m+1-starty;
                        }
                    }else{
                        if(m == (int)endy){
                            d = endy-m;
                        }else{
                            d = 1;
                        }
                    }
                    
                    if(d == 0 ){
                        break;
                    }
                    for(int n = (int) startx;n<=(int)endx;n++){
                        if(n == width){
                            break;
                        }
                        float dd;
                        if(n == (int)startx){
                            if(n == (int)endx){
                                dd = endx-startx;
                            }else{
                                dd = n+1-startx;
                            }
                        }else{
                            if(n == (int)endx){
                                dd = endx-n;
                            }else{
                                dd = 1;
                            }
                        }
                        color += d*dd*image[m][n];
                    }
                }
                if(color/((endy-starty)*(endx-startx))>=0.5){
                    letterImage[i][flag] = (letterImage[i][flag]<<1)+1;
                    count++;
                    if(count == 8){
                        flag++;
                        count = 0;
                    }
                }else{
                    letterImage[i][flag] = (letterImage[i][flag]<<1)+0;
                    count++;
                    if(count == 8){
                        flag++;
                        count = 0;
                    }
                }
            }
        }
        //        free2DArray((void**)image, imageHeight);
    }
    free(*image);
    free(image);
}
static void generateGrayImage(int8_t* arr,uc **grayImage,int imageWidth,int imageHeight,int hw,int hh,int x,int y,int w,int h, LibScanType type){
    float pixelwidth =(float)w/imageWidth;
    float pixelheight =(float)h/imageHeight;
    for(int j = 0;j<imageHeight;j++){
        for(int k = 0;k<imageWidth;k++) {
            float startx = x + k * pixelwidth;
            float starty = y + j * pixelheight;
            float endx = startx + pixelwidth;
            float endy = starty + pixelheight;
            float color = 0;
            for (int m = (int) starty; m <= (int) endy; m++) {
                if (m == y + h) {
                    break;
                }
                float d;
                if (m == (int) starty) {
                    if (m == (int) endy) {
                        d = endy - starty;
                    } else {
                        d = m + 1 - starty;
                    }
                } else {
                    if (m == (int) endy) {
                        d = endy - m;
                    } else {
                        d = 1;
                    }
                }
                if (d == 0) {
                    break;
                }
                for (int n = (int) startx; n <= (int) endx; n++) {
                    if (n == x + w) {
                        break;
                    }
                    float dd;
                    if (n == (int) startx) {
                        if (n == (int) endx) {
                            dd = endx - startx;
                        } else {
                            dd = n + 1 - startx;
                        }
                    } else {
                        if (n == (int) endx) {
                            dd = endx - n;
                        } else {
                            dd = 1;
                        }
                    }
                    color += d * dd * ((int) (*(arr + m * hw + n)) & 0xff);
                }
            }//original passport scanning is different from that
            if (type == LibScanIDCard) {
                if (color / ((endy - starty) * (endx - startx)) >= 0.5) {
                    if (endy != starty && endx != startx) {
                        grayImage[j][k] = roundf(color / ((endy - starty) * (endx - startx)));
                    }
                }
            }
            else {
                grayImage[j][k] = roundf(color / ((endy - starty) * (endx - startx)));
            }
        }
    }
}

//Scan ID Card
char* libOCRScanIDCard(int8_t *arr, int hw, int hh, int x, int y, int w, int h){
    uc **letterImage;//[18][25]={0};
    letterImage = (uc**)malloc(sizeof(uc*)*18);
    *letterImage = (uc*)malloc(18 * 25 * sizeof(uc));
    memset(*letterImage, 0, 18 * 25);
    for (int i = 1; i < 18; i++) {
        letterImage[i] = *letterImage + i * 25;
    }
    uc **grayImage;//[100][407]={0};
    grayImage = (uc**)malloc(sizeof(uc*)*100);
    *grayImage = (uc*)malloc(sizeof(**grayImage) * 100 * 407);
    memset(*grayImage, 0, 100 * 407);
    for (int i = 1; i < 100; i++) {
        grayImage[i] = *grayImage + i * 407;
    }
    uc **blackImage;//[100][51]={0};
    blackImage = (uc**)malloc(sizeof(uc*)*100);
    *blackImage = (uc*)malloc(sizeof(**blackImage) * 51 * 100);
    memset(*blackImage, 0, 51 * 100);
    for (int i = 1; i < 100; i++) {
        blackImage[i] = *blackImage + i * 51;
    }
    int width = 407;
    int height = 100;
    float angle = 0;
    int heightEdge[2]={0};
    generateGrayImage(arr,grayImage,407,100,hw,hh,x,y,w,h, LibScanIDCard);
    generateBlackImage(width,height,grayImage,blackImage);
    char *result = new char[19];
    memset(result, 0, 19 * sizeof(char));
    int upletterX[130] = {0};
    int upwhitespaces = 0;
    int **lettersxy;//[18][4] = {0};
    lettersxy = (int**)malloc(sizeof(int*)*18);
    *lettersxy = (int*)malloc(sizeof(**lettersxy) * 4 * 18);
    memset(*lettersxy, 0, 4 * 18);
    for (int i = 1; i < 18; i++) {
        lettersxy[i] = *lettersxy + 4 * i;
    }
    
    if(getHeightEdge(width,height,blackImage,51,100,&angle,(int*) heightEdge,LibScanIDCard)){
        if(generateLetterXIDCard(heightEdge[0],heightEdge[1],blackImage,angle,width,height,upletterX,&upwhitespaces)){
            if(getLettersXYIDCard(lettersxy,upletterX,heightEdge,blackImage,angle,width,height,upwhitespaces)){
                divideChar(blackImage,lettersxy,letterImage,18,407,100);
                ocr(letterImage,18,result,NULL,LibScanIDCard);
                printf("%s",result);
                if(checkValue(result)){
                    if(result[0] != 0){
                        int *numPos;
                        numPos = (int*)malloc(sizeof(int) * 72);
                        for (int i = 0; i < 18; i++) {
                            for (int j = 0; j < 4; j++) {
                                numPos[i * 4 + j] = lettersxy[i][j];
                            }
                        }
                        //save the positions of id card numbers to the program(implemeted in Objective-c file, which can be found in runtime)
                        saveNumPos(numPos);
                        free(numPos);
                    }
                    free(*blackImage);
                    free(blackImage);
                    free(*grayImage);
                    free(grayImage);
                    free(*letterImage);
                    free(letterImage);
                    free(*lettersxy);
                    free(lettersxy);
                    return result;
                }
            }
        }
    }
    else {
        printf("寻找上下边框失败");
    }
    free(*blackImage);
    free(blackImage);
    free(*grayImage);
    free(grayImage);
    free(*lettersxy);
    free(lettersxy);
    free(*letterImage);
    free(letterImage);
    result[0]=0;
    return result;
}

char* libOCRScanPassport(int8_t *arr,int hw,int hh,int x,int y,int w,int h){
    uc **letterImage;//[88][25]={0};//88 leters 13width 15 height;
    letterImage = (uc**)malloc(sizeof(uc*)*88);
    *letterImage = (uc*)malloc(88 * 25 * sizeof(uc));
    memset(*letterImage, 0, 88 * 25);
    for (int i = 1; i < 88; i++) {
        letterImage[i] = *letterImage + i * 25;
    }
    uc **grayImage;//[135][700]={0};
    grayImage = (uc**)malloc(sizeof(uc*)*135);
    *grayImage = (uc*)malloc(sizeof(**grayImage) * 135 * 700);
    memset(*grayImage, 0, 135 * 700);
    for (int i = 1; i < 135; i++) {
        grayImage[i] = *grayImage + i * 700;
    }
    
    uc **blackImage;//[135][88]={0};//135*700/8
    blackImage = (uc**)malloc(sizeof(uc*)*135);
    *blackImage = (uc*)malloc(sizeof(**blackImage) * 88 * 135);
    memset(*blackImage, 0, 88 * 135);
    for (int i = 1; i < 135; i++) {
        blackImage[i] = *blackImage + i * 88;
    }
    
    int width = 700;
    int height = 131;
    float angle = 0;
    int heightEdge[4]={0};
    generateGrayImage(arr,grayImage,700,131,hw,hh,x,y,w,h, LibScanPassport);
    generateBlackImage(width,height,grayImage,blackImage);
    char *result = new char[89];
    memset(result, 0, 89 * sizeof(char));
    int upletterX[130] = {0};
    int downletterX[130] = {0};
    int **lettersxy;//[88][4] = {0};
    lettersxy = (int**)malloc(sizeof(int*)*88);
    *lettersxy = (int*)malloc(sizeof(**lettersxy) * 4 * 88);
    memset(*lettersxy, 0, 4 * 88);
    for (int i = 1; i < 88; i++) {
        lettersxy[i] = *lettersxy + 4 * i;
    }
    
    int upwhitespaces = 0;
    int downwhitespaces = 0;
    if(getHeightEdge(width,height,blackImage,88,135,&angle,(int*) heightEdge,LibScanPassport)){
        if(generateLetterXPassport(heightEdge[0],heightEdge[1],blackImage,angle,width,height,upletterX,&upwhitespaces)&&generateLetterXPassport(heightEdge[2],heightEdge[3],blackImage,angle,width,height,downletterX,&downwhitespaces)){
            if(getLettersXYPassport(lettersxy,upletterX,downletterX,heightEdge,blackImage,angle,width,height,upwhitespaces,downwhitespaces)){
                divideChar(blackImage,lettersxy,letterImage,88,700,131);
                ocr(letterImage,88,result,NULL,LibScanPassport);
                printf("%s",result);
                if(result[0] != 0){
                    int *letterPos;
                    letterPos = (int *)malloc(88 * 4 * sizeof(int));
                    for (int i = 0; i < 88; i++) {
                        for (int j = 0; j < 4; j++) {
                            letterPos[4 * i + j] = lettersxy[i][j];
                        }
                    }
                    //save the positions of letters to the program
                    saveLetterPos(letterPos);
                    free(letterPos);
                    
                    free(*blackImage);
                    free(blackImage);
                    free(*grayImage);
                    free(grayImage);
                    free(*lettersxy);
                    free(lettersxy);
                    free(*letterImage);
                    free(letterImage);
                    return result;
                }
            }
        }
    }
    else {
        printf("寻找上下边框失败");
    }
    free(*blackImage);
    free(blackImage);
    free(*grayImage);
    free(grayImage);
    free(*lettersxy);
    free(lettersxy);
    free(*letterImage);
    free(letterImage);
    result[0] = 0;
    return result;
}

static const int kRed = 1;
static const int kGreen = 2;
static const int kBlue = 3;


UIImage *imageFromBitMap(int width, int height, uint8_t *imageData){
    UIImage *retImage;
    uint8_t *retImageData = (uint8_t*)calloc(sizeof(uint32_t) * width * height, 1);
    for (int i = 0; i < height * width; i++) {
        uint8_t *rgbPixel = (uint8_t *)&retImageData[4*i];
        int pixel = imageData[i];
        rgbPixel[kRed] = pixel;
        rgbPixel[kGreen] = pixel;
        rgbPixel[kBlue] = pixel;
    }
    
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(retImageData, width, height, 8, width*sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
    CGImageRef image=CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    retImage=[UIImage imageWithCGImage:image];
    CGImageRelease(image);
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:retImageData length:width*height];
    return retImage;
}
