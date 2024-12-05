//
//  MapViewService.swift
//  zSwing
//
//  Created by USER on 12/5/24.
//

import Foundation
import RxSwift
import MapKit

protocol MapViewServiceType {
    var regionDidChange: Observable<MKCoordinateRegion> { get }
    func setupDelegate(for mapView: MKMapView)
}

final class MapViewService: NSObject, MapViewServiceType, MKMapViewDelegate {
    private let regionSubject = PublishSubject<MKCoordinateRegion>()
    
    var regionDidChange: Observable<MKCoordinateRegion> {
        return regionSubject.asObservable()
    }
    
    func setupDelegate(for mapView: MKMapView) {
        mapView.delegate = self
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionSubject.onNext(mapView.region)
    }
}
