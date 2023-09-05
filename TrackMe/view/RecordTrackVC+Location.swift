/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages interactions with Core Location and AVFoundation for reporting when a user's location changes.
*/

import Alamofire
import AVFoundation
import CoreLocation
import Foundation
import UIKit

extension RecordTrackVC {
    
    /// Start receiving location updates from Core Location.
    // - Tag: location_manager_config
    func startRecordingLocation() {
        // Remove the existing path because the app is starting to record a new path.
        if let breadcrumbs {
            mapView.removeOverlay(breadcrumbs)
            breadcrumbPathRenderer = nil
        }
        
        // Create a fresh path when starting to record the locations.
        breadcrumbs = BreadcrumbPath()
        mapView.addOverlay(breadcrumbs, level: .aboveRoads)
        
        setupAudioPlayer()
        
        /**
         This app requests location while it's in use so it can continuously receive location updates, including
         while it's in the background, to create the breadcrumb overlay that shows the user's path.
         Because the app uses the standard location service, and starts it while in the foreground, location updates continue
         to arrive while the app is in the background, with the system displaying a location service indicator.
         */
        locationManager.requestWhenInUseAuthorization()
        
        /// Enable the app to collect location updates while it's in the background.
        locationManager.allowsBackgroundLocationUpdates = true
        
        /**
         By default, this sample uses the accuracy setting `kCLLocationAccuracyBest`.
         The correct choice of accuracy setting depends on the specific needs for an app.
        */
        locationManager.desiredAccuracy = locationAccuracy
        
        /// Provide a hint to Core Location on the type of activity for the location updates.
        locationManager.activityType = activityType
        
        /// Certain activity types may pause location updates if the device doesn't move for a period of time. The nature of this project
        /// to show a map of the update history means that updates don't pause.
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // TODO: 5초 후의 업데이트 정보만 저장하도록 수정
        /// Start tracking the user's location.
        locationManager.startUpdatingLocation()
       
        isMonitoringLocation = true
        
    }
    
    /// Stop receiving location updates from Core Location.
    func stopRecordingLocation() {
        
        isMonitoringLocation = false
        
        locationManager.stopUpdatingLocation()
        tearDownAudioPlayer()
        
        showTitleInputModal()
    }
    
    private func showTitleInputModal() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Enter Title", message: nil, preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "트랙명을 입력하세요."
            }
            
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let text = alertController.textFields?.first?.text, !text.isEmpty {
                    self.trackTitle = text
                    self.tranferNewTrack()
                } else {
                    alertController.message = "트랙명을 반드시 입력해야 합니다."

                    // Keep the UIAlertController open (no action needed here)
                    // You can add additional actions if desired

                    // Ensure the UIAlertController is still presented
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func tranferNewTrack() {
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        let startTime = breadcrumbs.locations.first!.timestamp
        let elapsedTime = breadcrumbs.locations.last!.timestamp.timeIntervalSince(startTime)
        let path = breadcrumbs.locations.map { location in
            let coord = location.coordinate
            let elapsedTime = location.timestamp.timeIntervalSince(startTime)
            return ["latitude":coord.latitude, "longitude":coord.longitude, "elapsedTime": elapsedTime]
        }
        
        // [http 요청 파라미터 지정 실시]
        let bodyData : Parameters = [
            "title" : trackTitle!,
            "path" : path,
            "distance" : breadcrumbs.distance,
            "trackRecord" : [
                "path" : path,
                "distance" : breadcrumbs.distance,
                "time" : elapsedTime
            ] as [String : Any]
        ]
        
        AF.request("http://localhost:8080/tracks",
                   method: .post,
                   parameters: bodyData, // [전송 데이터]
                   encoding: JSONEncoding.default, // [인코딩 스타일]
                   headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(_):
                print("new track created!")
                break;
            case .failure(let error):
                print(error)
                break;
            }
        }
    }
}

extension RecordTrackVC: CLLocationManagerDelegate {
    
    // - Tag: location_manager_delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Play a sound so it's easy to tell when a location update occurs while the app is in the background.
        if chimeOnLocationUpdate && !locations.isEmpty {
            setSessionActiveWithMixing(true) // Ducks the audio of other apps when playing the chime.
            playSound()
        }
        
        // Always process all of the provided locations. Don't assume the array only contains a single location.
        for location in locations {
            displayNewBreadcrumbOnMap(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            // The app doesn't have access to location data. Inform the user.
            let title = "This device has restricted access to your location."
            let message = "Open Settings to change access."
            let okTitle = "OK"
            let settingsTitle = "Settings"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: okTitle, style: .cancel)
            alert.addAction(okAction)
            
            let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            alert.addAction(settingsAction)
            
            present(alert, animated: true)
        }
    }
}

extension RecordTrackVC: AVAudioPlayerDelegate {
    
    private func setupAudioPlayer() {
        setSessionActiveWithMixing(false)
        if let sound = Bundle.main.url(forResource: "bells", withExtension: "aif") {
            audioPlayer = try! AVAudioPlayer(contentsOf: sound)
        }
    }
    
    private func tearDownAudioPlayer() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func setSessionActiveWithMixing(_ duckIfOtherAudioIsPlaying: Bool) {
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        if AVAudioSession.sharedInstance().isOtherAudioPlaying && duckIfOtherAudioIsPlaying {
            try! AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
        }
        
        try! AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func playSound() {
        guard let audioPlayer else { return }
        if audioPlayer.isPlaying == false {
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        try! AVAudioSession.sharedInstance().setActive(false)
    }
}
