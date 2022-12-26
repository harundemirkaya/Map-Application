//
//  ViewController.swift
//  MapApp
//
//  Created by Harun Demirkaya on 23.12.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var txtFieldTitle: UITextField!
    @IBOutlet weak var txtFieldSubtitle: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblFillFields: UILabel!
    @IBOutlet weak var btnSave: UIButton!
    var locationManager = CLLocationManager()
    var latitude = Double()
    var longitude = Double()
    var selectID: UUID?
    var annotationLongitude = 0.0
    var annotationLatitude = 0.0
    var annotationTitle = ""
    var annotationSubtitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblFillFields.isHidden = true
        btnSave.isEnabled = false
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gesturRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        gesturRecognizer.minimumPressDuration = 0.1
        mapView.addGestureRecognizer(gesturRecognizer)
        
        if selectID != nil{
            if let id = selectID?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                fetchRequest.predicate = NSPredicate(format: "id = %@", id)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let results = try context.fetch(fetchRequest)
                    if results.count > 0{
                        for result in results as! [NSManagedObject]{
                            if let title = result.value(forKey: "title") as? String, let subTitle = result.value(forKey: "subTitle") as? String{
                                annotationTitle = title
                                annotationSubtitle = subTitle
                                txtFieldTitle.text = annotationTitle
                                txtFieldSubtitle.text = annotationSubtitle
                                
                                if let longitude = result.value(forKey: "longitude") as? Double, let latitude = result.value(forKey: "latitude") as? Double{
                                    let annotation = MKPointAnnotation()
                                    annotation.title = title
                                    annotation.subtitle = subTitle
                                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                    annotationLatitude = latitude
                                    annotationLongitude = longitude
                                    annotation.coordinate = coordinate
                                    mapView.addAnnotation(annotation)
                                    
                                    locationManager.startUpdatingLocation()
                                    let location = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                                    let region = MKCoordinateRegion(center: location, span: span)
                                    mapView.setRegion(region, animated: true)
                                }
                            }
                        }
                    }
                } catch{
                    print("Error")
                }
            }
        } else{
            txtFieldTitle.text = ""
            txtFieldSubtitle.text = ""
        }
    }
    
    @objc func selectLocation(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let touchedPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            
            if txtFieldTitle.text == "" || txtFieldSubtitle.text == ""{
                lblFillFields.isHidden = false
                btnSave.isEnabled = false
            } else{
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinate
                annotation.title = txtFieldTitle.text
                annotation.subtitle = txtFieldSubtitle.text
                lblFillFields.isHidden = true
                longitude = touchedCoordinate.longitude
                latitude = touchedCoordinate.latitude
                btnSave.isEnabled = true
                mapView.addAnnotation(annotation)
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print(locations[0].coordinate.latitude)
        //print(locations[0].coordinate.longitude)
        if selectID == nil{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    @IBAction func btnSave(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        newLocation.setValue(txtFieldTitle.text, forKey: "title")
        newLocation.setValue(txtFieldSubtitle.text, forKey: "subTitle")
        newLocation.setValue(longitude, forKey: "longitude")
        newLocation.setValue(latitude, forKey: "latitude")
        newLocation.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Kayıt Başarılı")
        } catch{
            print("Error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "saved") , object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reUseID = "annotationID"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reUseID)
        
        if pinView == nil{
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reUseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let btnInfo = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = btnInfo
        } else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectID != nil{
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placeMarksArray, err in
                if let placeMarks = placeMarksArray{
                    if placeMarks.count > 0{
                        let newPlaceMark = MKPlacemark(placemark: placeMarks[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving ]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }
    
}

