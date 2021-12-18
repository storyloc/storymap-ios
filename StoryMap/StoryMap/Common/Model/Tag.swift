//
//  Categories.swift
//  StoryMap
//
//  Created by Dory on 18/12/2021.
//

import Foundation

enum Tag: String, CaseIterable {
	case shopping
	case sightseeing
	case hikes
	case nature
	case food
	case museum
	case coffee
}

extension Tag {
	var localizedTitle: String {
		switch self {
		case .coffee: return LocalizationKit.tags.coffee
		case .shopping: return LocalizationKit.tags.shopping
		case .sightseeing: return LocalizationKit.tags.sightseeing
		case .hikes: return LocalizationKit.tags.hikes
		case .nature: return LocalizationKit.tags.nature
		case .food: return LocalizationKit.tags.food
		case .museum: return LocalizationKit.tags.museum
		}
	}
}
