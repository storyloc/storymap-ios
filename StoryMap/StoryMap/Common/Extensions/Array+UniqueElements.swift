//
//  Array+UniqueElements.swift
//  StoryMap
//
//  Created by Dory on 18/12/2021.
//

extension Array where Element: Equatable {
	func uniqueElements() -> [Element] {
		var unique = [Element]()
		
		for element in self {
			if !unique.contains(element) {
				unique.append(element)
			}
		}
		
		return unique
	}
}
