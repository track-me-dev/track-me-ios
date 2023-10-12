import UIKit
import Alamofire
import KeychainSwift

class RankingVC: UIViewController {
    
    var trackId: CLong!
    var trackRecords: [TrackRecord] = []
    var currentPage: Int = 0
    var isLastPage: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "RankCell", bundle: nil), forCellReuseIdentifier: "rankCell")
        
        requestTrackRecords()
    }
    
    private func formatElaspsedTime(_ time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func requestTrackRecords() {
        let keychain = KeychainSwift()
        let header : HTTPHeaders = [
            "Content-Type" : "application/json",
            "Authorization" : "Bearer \(keychain.get("trackme_accessToken")!)"
        ]
        AF.request("http://localhost:8080/tracks/\(Int(trackId))/records?page=\(currentPage)",
                   method: .get,
                   headers: header)
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    do {
                        let result = try JSONDecoder().decode(TrackRecordResponse.self, from: value!)
                        DispatchQueue.main.async {
                            self.trackRecords.append(contentsOf: result.content)
                            self.isLastPage = result.last
                            self.tableView.reloadData()
                        }
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    print(error)
                    break;
                }
            }
    }
}

extension RankingVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2; // section: 0, 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // section이 0인 경우 cell의 개수는 trackRecord의 개수
            return trackRecords.count
        } else { // section이 1인 경우 cell의 개수는 1개
            return 1;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rankCell", for: indexPath)
        switch indexPath.section {
        case 0:
            let record = trackRecords[indexPath.row]
            cell.textLabel?.text = "\(indexPath.row + 1). \(record.username)"
            cell.detailTextLabel?.text = "\(formatElaspsedTime(record.time))"
            cell.detailTextLabel?.isHidden = false
            cell.isHidden = false
            break
        case 1:
            cell.textLabel?.text = "더 보기"
            cell.textLabel?.textAlignment = .center
            cell.detailTextLabel?.isHidden = true
            cell.isUserInteractionEnabled = true
            if isLastPage {
                cell.isHidden = true
            }
            break
        default: break
        }
        return cell
    }
}

extension RankingVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            return
        }
        // section이 1인 경우
        currentPage += 1
        requestTrackRecords()
    }
}





