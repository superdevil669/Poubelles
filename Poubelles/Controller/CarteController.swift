//
//  CarteController.swift
//  Poubelles
//
//  Created by Jean-François Coquerelle on 17/06/18.
//  Copyright © 2018 Jean-François Coquerelle. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class CarteController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var carte: MKMapView!
    @IBOutlet weak var maPositionBouton: UIButton!
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var urlString = ""
    var locationManager = CLLocationManager()
    var poubelles: Poubelles?
    var imagesGlyph = UIImage()
    var imageRightCallout = UIImage(named: "")
    
    var labelNames: [String] = Array()
    var selected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        carte.delegate = self
        carte.showsUserLocation = true
        carte.showsScale = true
        carte.showsCompass = true
        
        miseEnPlace()
        obtenirDonneesDepuisJSON()
        
// MARK PickerView Label
        labelNames.append("Poubelles publique")
        labelNames.append("Ecart poubelle du Mardi")
        labelNames.append("Marche à bâton")
// MARK Charge le 1 JSON du pickerView au chargement de l'appli
        pickerView.selectRow(0, inComponent: 0, animated: true)
        self.carte.removeAnnotations(self.carte.annotations)
        urlString = UrlDeBase + PoubellePublique
        imagesGlyph = UIImage(named: "poubelles")!
        obtenirDonneesDepuisJSON()
        
    }
    
    func obtenirDonneesDepuisJSON() {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard data != nil else { return }
            do {
                self.poubelles = try JSONDecoder().decode(Poubelles.self, from: data!)
                DispatchQueue.main.async {
                    self.obtenirAnnotations()
                }
                
            } catch {
                print(error.localizedDescription)
            }
            }.resume()
    }
    
    func obtenirAnnotations() {
        guard let poubellesNonOptionnelle = self.poubelles else { return }
        
        for poubelle in poubellesNonOptionnelle.features {
            imageRightCallout = UIImage(named: poubelle.properties.icones)
            let latitude = Double(poubelle.geometry.coordinates[1])
            let longitude = Double(poubelle.geometry.coordinates[0])
//            print(latitude)
            
            // if let latitude = Double(latitudeString), let longitude = Double(longitudeString) {
            let coordonnes = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let titre = poubelle.properties.name
            let desc = poubelle.properties.desc
            let location = CLLocation(latitude: latitude, longitude: longitude)
            MonGeocoder.obtenir.adresseDepuis(location, completion: { (adresse, erreur) -> (Void) in
                var monAdresse = ""
                if adresse != nil {
                    monAdresse = adresse!
                }
                let monAnnotation = MonAnnotation(titre: titre, adresse: desc + "\n" + monAdresse, descr: "", coordonnes: coordonnes)
                self.carte.addAnnotation(monAnnotation)
            })
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationViewPoubelle = MKMarkerAnnotationView()
        guard annotation is MonAnnotation else { return  nil }
        let identifier = "Poubelle"
        if let dequedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            annotationViewPoubelle = dequedView
        }else {
            annotationViewPoubelle = MKMarkerAnnotationView(annotation: annotationViewPoubelle as? MKAnnotation, reuseIdentifier: identifier)
        }
        
        annotationViewPoubelle.glyphImage = imagesGlyph
        annotationViewPoubelle.clusteringIdentifier = "identifier"
        annotationViewPoubelle.canShowCallout = true
        
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = annotation.subtitle!
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        annotationViewPoubelle.detailCalloutAccessoryView = subtitleLabel
        
        let imageleft = UIImage(named: "ios11maps") as UIImage?
        let navigationButton = UIButton(type: .custom) as UIButton
        navigationButton.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        navigationButton.setImage(imageleft, for: .normal)
        annotationViewPoubelle.leftCalloutAccessoryView = navigationButton
        
        let imageright = imageRightCallout
        let rightButton = UIButton(type: .custom) as UIButton
        rightButton.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        rightButton.setImage(imageright, for: .normal)
        annotationViewPoubelle.rightCalloutAccessoryView = rightButton
        
        return annotationViewPoubelle
    }
    
    // MARK Itinéraire vers le point séléctioné
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        
        let selectedLoc = view.annotation
        
//        print("Annotation '\(String(describing: selectedLoc?.title!))' has been selected")
        let currentLocMapItem = MKMapItem.forCurrentLocation()
        let selectedPlacemark = MKPlacemark(coordinate: (selectedLoc?.coordinate)!, addressDictionary: nil)
        let selectedMapItem = MKMapItem(placemark: selectedPlacemark)
        selectedMapItem.name = (selectedLoc?.title)!
        let mapItems = [currentLocMapItem, selectedMapItem]
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        MKMapItem.openMaps(with: mapItems, launchOptions:launchOptions)
    }
    
//MARK PickerVIew
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return labelNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return labelNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected = row
        if (selected == 0) {
            self.carte.removeAnnotations(self.carte.annotations)
            urlString = UrlDeBase + PoubellePublique
            imagesGlyph = UIImage(named: "poubelles")!
            obtenirDonneesDepuisJSON()
        } else if (selected == 1) {
            self.carte.removeAnnotations(self.carte.annotations)
            urlString = ""
            obtenirDonneesDepuisJSON()
        } else if (selected == 2) {
            self.carte.removeAnnotations(self.carte.annotations)
            urlString = UrlDeBase + MarcheABaton
            imagesGlyph = UIImage(named: "Group")!
            obtenirDonneesDepuisJSON()
        }
    }

//MARK BUTTON
    @IBAction func meLocaliser(_ sender: Any) {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func segmentChoisi(_ sender: Any) {
        switch segment.selectedSegmentIndex {
        case 0: carte.mapType = .standard
        case 1: carte.mapType = .satellite
        case 2: carte.mapType = .hybrid
        default: break
        }
    }

}
