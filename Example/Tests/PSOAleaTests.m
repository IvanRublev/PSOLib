//
//  PSOLibTests.m
//  PSOLibTests
//
//  Created by Ivan Rublev on 11/04/2015.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
@import PSOLib;


SpecBegin(PSOAlea)

describe(@"Random generators that should return uniformly distributed values.", ^{
    
    beforeAll(^{
        PSOAleaSrand(1294404794);
    });
    it(@"alea", ^{
        double min = -1.;
        double max = 1.;
        int barsCount = 10;
        int* bars = calloc(sizeof(int), barsCount);
        double step = (max-min)/barsCount;
        int valuesCount = barsCount*100;
        
        for (int i=0; i<valuesCount; i++) {
            double randValue = PSOAlea(min, max);
            NSUInteger idx = 0;
            for (double w=min; w < max; w+=step, idx++) {
                if ((idx == 0 && randValue == w) ||
                    (w < randValue && randValue <= w+step)) {
                    bars[idx] += 1;
                    break;
                }
            }
        }
        // Find mean
        double meanValuesCount = 0;
        for (int i=0; i<barsCount; i++) {
            // NSLog(@"bars: %d", bars[i]);
            meanValuesCount += bars[i];
        }
        meanValuesCount /= barsCount;
        // Check deviations in each bar to be no more then 12%
        for (int i=0; i<barsCount; i++) {
            expect(bars[i]).to.beGreaterThanOrEqualTo(meanValuesCount*0.88);
        }
        free(bars);
    });
    
    
    it(@"aleaInSphereWithRadius", ^{
        double radius = 5;
        int dimensions = 3;
        double* xValues = malloc(sizeof(double)*dimensions);
        int valuesCount = 1000;
        for (int i=0; i<valuesCount; i++) {
            PSOAleaInSphere(5, xValues, dimensions);
            // NSLog(@"%.2f", xValues[0]);
            for (size_t d=0; d<dimensions; d++) {
                expect(xValues[d]).to.beLessThan(radius);
            }
        }
        free(xValues);
    });
    
});

SpecEnd
