//
//  MONUniformFlowLayout.m
//
//  Created by mownier on 12/2/14.
//  Copyright (c) 2014 mownier. All rights reserved.
//

#import "MONUniformFlowLayout.h"

@interface MONUniformFlowLayout ()

@property (readonly, nonatomic) CGFloat collectionViewContentHeight;

@property (readonly, nonatomic) CGFloat headerWidth;
@property (readonly, nonatomic) CGFloat footerWidth;

@property (readonly, nonatomic) NSInteger numberOfSections;
@property (readonly, nonatomic) CGFloat sectionSpacing;

- (CGFloat)computeItemHeightInSection:(NSInteger)section;
- (CGFloat)computeTotalInterItemSpacingYInSection:(NSInteger)section;
- (CGFloat)computeTotalItemHeightInSection:(NSInteger)section;
- (CGFloat)computePositionYInSection:(NSInteger)section;

- (CGFloat)computeHeaderPositionYInSection:(NSInteger)section;
- (CGFloat)computeFooterPositionYInSection:(NSInteger)section;

- (NSInteger)getNumberOfRowsInSection:(NSInteger)section;
- (NSInteger)getNumberOfItemsInSection:(NSInteger)section;
- (NSInteger)getNumberOfColumnsInSection:(NSInteger)section;

- (CGFloat)getHeaderHeightInSection:(NSInteger)section;
- (CGFloat)getFooterHeightInSection:(NSInteger)section;

- (void)modifyItemAttributes:(UICollectionViewLayoutAttributes *)attributes indexPath:(NSIndexPath *)indexPath;
- (void)modifyHeaderAttributes:(UICollectionViewLayoutAttributes *)attributes section:(NSInteger)section;
- (void)modifyFooterAttributes:(UICollectionViewLayoutAttributes *)attributes section:(NSInteger)section;

@end

@implementation MONUniformFlowLayout

#pragma mark -
#pragma mark - Layout

- (void)prepareLayout {
    [super prepareLayout];
}

#pragma mark -
#pragma mark - Attributes Modification

- (void)modifyItemAttributes:(UICollectionViewLayoutAttributes *)attributes indexPath:(NSIndexPath *)indexPath {
    NSInteger currentSection = indexPath.section;
    NSInteger currentRow = indexPath.row / [self getNumberOfColumnsInSection:currentSection];
    NSInteger currentColumn = indexPath.row % [self getNumberOfColumnsInSection:currentSection];
    
    CGRect frame = attributes.frame;
    
    frame.origin.x = (self.interItemSpacing.x * currentColumn) + ([self computeItemWidthInSection:currentSection] * currentColumn);
    frame.origin.y = [self computePositionYInSection:currentSection] + (self.interItemSpacing.y * currentRow) + ([self computeItemHeightInSection:currentSection] * currentRow);
    frame.size.width = [self computeItemWidthInSection:currentSection];
    frame.size.height = [self computeItemHeightInSection:currentSection];
    
    attributes.frame = frame;
}

- (void)modifyHeaderAttributes:(UICollectionViewLayoutAttributes *)attributes section:(NSInteger)section {
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    
    CGRect frame = attributes.frame;
    frame.origin.x = -self.collectionView.contentInset.left;
    frame.origin.y = [self computeHeaderPositionYInSection:section];
    frame.size.width = self.headerWidth;
    frame.size.height = [delegate collectionView:self.collectionView layout:self headerHeightInSection:section];
    attributes.frame = frame;
    attributes.zIndex = 1024;
}

- (void)modifyFooterAttributes:(UICollectionViewLayoutAttributes *)attributes section:(NSInteger)section {
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    
    CGRect frame = attributes.frame;
    frame.origin.x = -self.collectionView.contentInset.left;
    frame.origin.y = [self computeFooterPositionYInSection:section];
    frame.size.width = self.footerWidth;
    frame.size.height = [delegate collectionView:self.collectionView layout:self footerHeightInSection:section];
    attributes.frame = frame;
    attributes.zIndex = 1024;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
        [self modifyHeaderAttributes:attributes section:indexPath.section];
        return attributes;
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:indexPath];
        
        [self modifyFooterAttributes:attributes section:indexPath.section];
        return attributes;
    }
    return nil;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    [self modifyItemAttributes:attributes indexPath:indexPath];
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *allAttributesInRect = [NSMutableArray new];
    
    NSUInteger numberOfSections = self.numberOfSections;
    for (int section = 0; section < numberOfSections; section++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        
        UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        if (headerAttributes && CGRectIntersectsRect(headerAttributes.frame, rect)) {
            [allAttributesInRect addObject:headerAttributes];
        }

        UICollectionViewLayoutAttributes *footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
        if (footerAttributes && CGRectIntersectsRect(footerAttributes.frame, rect)) {
            [allAttributesInRect addObject:footerAttributes];
        }
        
        NSUInteger numberOfItems = [self getNumberOfItemsInSection:section];
        for (int item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            if (CGRectIntersectsRect(attributes.frame, rect)) {
                [allAttributesInRect addObject:attributes];
            }
        }
    }
    
    return allAttributesInRect;
}

#pragma mark -
#pragma mark - Content Size

- (CGSize)collectionViewContentSize {
    CGSize contentSize = [super collectionViewContentSize];
    contentSize.height = self.collectionViewContentHeight;
    return contentSize;
}

- (CGFloat)collectionViewContentHeight {
    NSInteger lastSection = self.numberOfSections - 1;
    CGFloat height = [self computePositionYInSection:lastSection] + [self getFooterHeightInSection:lastSection] + [self computeTotalInterItemSpacingYInSection:lastSection] + [self computeTotalItemHeightInSection:lastSection];
    
    return MAX(height, self.collectionView.frame.size.height);
}

#pragma mark -
#pragma mark - Header and Footer

- (CGFloat)headerWidth {
    return self.collectionView.frame.size.width;
}

- (CGFloat)footerWidth {
    return self.collectionView.frame.size.width;
}

- (CGFloat)getHeaderHeightInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    CGFloat headerHeight = 0;
    if (delegate && [delegate respondsToSelector:@selector(collectionView:layout:headerHeightInSection:)]) {
        headerHeight = [delegate collectionView:self.collectionView layout:self headerHeightInSection:section];
    }
    return headerHeight;
}

- (CGFloat)getFooterHeightInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    CGFloat footerHeight = 0;
    if (delegate && [delegate respondsToSelector:@selector(collectionView:layout:footerHeightInSection:)]) {
        footerHeight = [delegate collectionView:self.collectionView layout:self footerHeightInSection:section];
    }
    return footerHeight;
}

- (CGFloat)computeFooterPositionYInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    // y-position of last row in section + itemHeightInSection + footerHeightInSection
    NSInteger lastRow = [self getNumberOfRowsInSection:section] - 1;
    CGFloat posiitonY = ([self computePositionYInSection:section] + (self.interItemSpacing.y * lastRow) + ([self computeItemHeightInSection:section] * lastRow)) + [self computeItemHeightInSection:section];
    return posiitonY;
}

- (CGFloat)computeHeaderPositionYInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    // y-position of the first row in section - headerHeightInSection
    CGFloat positionY = [self computePositionYInSection:section] - [self getHeaderHeightInSection:section];
    if (self.enableStickyHeader) {
        CGFloat offsetY = self.collectionView.contentOffset.y;
        CGFloat offsetYToStick = positionY - self.collectionView.contentInset.top;
        CGFloat offsetYToGetOff = [self computeFooterPositionYInSection:section] - [self getHeaderHeightInSection:section] - self.collectionView.contentInset.top;
        if (offsetY >= offsetYToStick && offsetY < offsetYToGetOff) {
            return self.collectionView.contentInset.top + self.collectionView.contentOffset.y;
        } else if (offsetY >= offsetYToGetOff) {
            return self.collectionView.contentInset.top + self.collectionView.contentOffset.y - (offsetY - offsetYToGetOff); // (scrollUp1: -1, scrollUp2: -2, scrollUp3: -3)
        }
    }
    return positionY;
}

#pragma mark -
#pragma mark - Item Size in Section

- (CGFloat)computeItemWidthInSection:(NSInteger)section {
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    NSUInteger numberOfColumnsInSection = [delegate collectionView:self.collectionView layout:self numberOfColumnsInSection:section];
    CGFloat deductions = self.collectionView.contentInset.left + self.collectionView.contentInset.right + (self.interItemSpacing.x * (numberOfColumnsInSection - 1));
    CGFloat width = (self.collectionView.frame.size.width - deductions) / numberOfColumnsInSection;
    return width;
}

- (CGFloat)computeItemHeightInSection:(NSInteger)section {
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    CGFloat height = [delegate collectionView:self.collectionView layout:self itemHeightInSection:section];
    return height;
}

#pragma mark -
#pragma mark - Number of Items

- (NSInteger)getNumberOfItemsInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
    return numberOfItems;
}

#pragma mark -
#pragma mark - Sections

- (NSInteger)numberOfSections {
    NSInteger numberOfSections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
    return numberOfSections;
}

- (CGFloat)sectionSpacing {
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    CGFloat sectionSpacing = 0;
    if (delegate && [delegate respondsToSelector:@selector(collectionView:sectionSpacingForlayout:)]) {
        sectionSpacing = [delegate collectionView:self.collectionView sectionSpacingForlayout:self];
    }
    return sectionSpacing;
}

#pragma mark -
#pragma mark - Rows

- (NSInteger)getNumberOfRowsInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    NSInteger numberOfItems = [self getNumberOfItemsInSection:section];
    NSInteger numberOfRows = ceil(numberOfItems / ([self getNumberOfColumnsInSection:section] * 1.0f));
    return numberOfRows;
}

#pragma mark -
#pragma mark - Columns

- (NSInteger)getNumberOfColumnsInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    id<SimpleFlowLayoutDelegate> delegate = (id<SimpleFlowLayoutDelegate>)self.collectionView.delegate;
    NSInteger numberOfColumns = 1;
    if (delegate && [delegate respondsToSelector:@selector(collectionView:layout:numberOfColumnsInSection:)]) {
        numberOfColumns = [delegate collectionView:self.collectionView layout:self numberOfColumnsInSection:section];
    }
    return numberOfColumns;
}

#pragma mark -
#pragma mark - Inter Item Spacing

- (CGFloat)computeTotalInterItemSpacingYInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    NSInteger numberOfRowsInSection = [self getNumberOfRowsInSection:section];
    CGFloat totalInterItemSpacingYInSection = (self.interItemSpacing.y * (numberOfRowsInSection - 1));
    return totalInterItemSpacingYInSection;
}

#pragma mark -
#pragma mark - Total Height In Section

- (CGFloat)computeTotalItemHeightInSection:(NSInteger)section {
    if (section < 0) {
        return 0;
    }
    NSInteger numberOfRowsInSection = [self getNumberOfRowsInSection:section];
    CGFloat itemHeight = [self computeItemHeightInSection:section];
    CGFloat totalHeightInSection = itemHeight * numberOfRowsInSection;
    return totalHeightInSection;
}

#pragma mark -
#pragma mark - Overidden Setters and Getterss

- (void)setInterItemSpacing:(InterItemSpacing)interItemSpacing {
    _interItemSpacing = interItemSpacing;
    [self invalidateLayout];
}

#pragma mark -
#pragma mark - Position Y Computation

- (CGFloat)computePositionYInSection:(NSInteger)section {
    CGFloat totalInterSectionSpacing = self.sectionSpacing * section;
    CGFloat totalInterItemSpacingY = 0;
    CGFloat totalSectionItemHeight = 0;
    CGFloat totalHeaderHeight = [self getHeaderHeightInSection:section];
    CGFloat totalFooterHeight = 0;
    
    for (NSInteger i = 0; i < section; i++) {
        totalInterItemSpacingY += [self computeTotalInterItemSpacingYInSection:i];
        totalSectionItemHeight += [self computeTotalItemHeightInSection:i];
        totalHeaderHeight += [self getHeaderHeightInSection:i];
        totalFooterHeight += [self getFooterHeightInSection:i];
    }
    
    CGFloat positionY = totalSectionItemHeight + totalInterSectionSpacing + totalInterItemSpacingY + totalHeaderHeight + totalFooterHeight;
    return positionY;
}

#pragma mark -
#pragma mark - Invalidate Layout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end