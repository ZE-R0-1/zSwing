//
//  PlaygroundDetailRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift
import Firebase

protocol PlaygroundDetailRepository {
    func getPlaygroundDetail(id: String) -> Observable<PlaygroundDetailDTO>
}
