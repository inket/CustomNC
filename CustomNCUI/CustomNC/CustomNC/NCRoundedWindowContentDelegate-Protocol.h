/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

@protocol NCRoundedWindowContentDelegate <NSObject>

@optional
- (void)contentView:(id)arg1 velocity:(double)arg2 draggedCompleted:(BOOL)arg3;
- (void)contentView:(id)arg1 dragged:(id)arg2;
- (BOOL)contentView:(id)arg1 dragStarted:(id)arg2;
- (void)contentViewLayedOut:(id)arg1;
- (BOOL)contentView:(id)arg1 scrolled:(id)arg2;
- (void)contentViewCloseButtonClicked:(id)arg1;
- (void)contentView:(id)arg1 mouseEntered:(BOOL)arg2;
- (void)contentView:(id)arg1 mouseClicked:(long long)arg2;
@end

