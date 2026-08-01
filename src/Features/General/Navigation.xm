#import "../../Utils.h"

BOOL isSurfaceShown(IGMainAppSurfaceIntent *surface) {
    BOOL isShown = YES;

    // Feed
    if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"FEED"] && [SCIUtils getBoolPref:@"hide_feed_tab"]) {
        isShown = NO;
    }
    
    // Reels
    else if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"CLIPS"] && [SCIUtils getBoolPref:@"hide_reels_tab"]) {
        isShown = NO;
    }

    // Explore
    else if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"SEARCH"] && [SCIUtils getBoolPref:@"hide_explore_tab"]) {
        isShown = NO;
    }

    // Create
    else if ([(NSNumber *)[surface valueForKey:@"_subtype"] unsignedIntegerValue] == 3 && [SCIUtils getBoolPref:@"hide_create_tab"]) {
        isShown = NO;
    }

    return isShown;
}

// Sekmeleri özel sıraya koyan fonksiyon
NSArray *reorderSurfacesCustom(NSArray *surfaces) {
    NSMutableArray *filteredSurfaces = [NSMutableArray array];

    for (IGMainAppSurfaceIntent *surface in surfaces) {
        if (![surface isKindOfClass:%c(IGMainAppSurfaceIntent)]) break;

        if (isSurfaceShown(surface)) {
            [filteredSurfaces addObject:surface];
        }
    }

    // Özel Sıralama Mantığı: Home -> Direct (DM) -> Search (Keşfet) -> Clips (Reels) -> Profile
    NSMutableArray *customOrdered = [NSMutableArray array];
    id homeSurface = nil;
    id directSurface = nil;
    id searchSurface = nil;
    id reelsSurface = nil;
    id profileSurface = nil;
    NSMutableArray *otherSurfaces = [NSMutableArray array];

    for (id surface in filteredSurfaces) {
        NSString *tabString = @"";
        if ([surface respondsToSelector:@selector(tabStringFromSurfaceIntent)]) {
            tabString = [surface tabStringFromSurfaceIntent];
        }

        if ([tabString isEqualToString:@"FEED"]) {
            homeSurface = surface;
        } else if ([tabString isEqualToString:@"DIRECT"] || [tabString isEqualToString:@"DIRECT_THREAD_LIST"]) {
            directSurface = surface;
        } else if ([tabString isEqualToString:@"SEARCH"]) {
            searchSurface = surface;
        } else if ([tabString isEqualToString:@"CLIPS"]) {
            reelsSurface = surface;
        } else if ([tabString isEqualToString:@"PROFILE"]) {
            profileSurface = surface;
        } else {
            [otherSurfaces addObject:surface];
        }
    }

    // İstediğin tam sıralamayı diziyoruz
    if (homeSurface) [customOrdered addObject:homeSurface];
    if (directSurface) [customOrdered addObject:directSurface]; // DM 2. sırada!
    if (searchSurface) [customOrdered addObject:searchSurface];
    if (reelsSurface) [customOrdered addObject:reelsSurface];
    if (profileSurface) [customOrdered addObject:profileSurface];
    
    // Eğer dışarıda kalan başka bir sekme varsa sonuna ekle
    [customOrdered addObjectsFromArray:otherSurfaces];

    return customOrdered.count > 0 ? customOrdered : filteredSurfaces;
}

///////////////////////////////////////////////

%hook IGTabBarControllerSwipeCoordinator
- (id)initWithSurfaces:(id)surfaces parentViewController:(id)controller enableHaptics:(_Bool)haptics launcherSet:(id)set {
    return %orig(reorderSurfacesCustom(surfaces), controller, haptics, set);
}
%end

%hook IGTabBarController
- (void)_layoutTabBar {
    NSArray *_tabBarSurfaces = [SCIUtils getIvarForObj:self name:"_tabBarSurfaces"];
    [SCIUtils setIvarForObj:self name:"_tabBarSurfaces" value:reorderSurfacesCustom(_tabBarSurfaces)];
    %orig;
}

- (id)_buttonForTabBarSurface:(id)surface {
    id button = %orig(surface);

    if (!isSurfaceShown(surface)) {
        return nil;
    }

    return button;
}
%end

// Demangled name: IGNavConfiguration.IGNavConfiguration
%hook _TtC18IGNavConfiguration18IGNavConfiguration
- (NSInteger)tabOrdering {
    return %orig;
}
- (void)setTabOrdering:(NSInteger)arg1 {
    return;
}

- (BOOL)isTabSwipingEnabled {
    if ([[SCIUtils getStringPref:@"swipe_nav_tabs"] isEqualToString:@"enabled"]) return YES;
    else if ([[SCIUtils getStringPref:@"swipe_nav_tabs"] isEqualToString:@"disabled"]) return NO;
    return %orig;
}
- (void)setIsTabSwipingEnabled:(BOOL)arg1 {
    return;
}
%end
