import UIKit
import Alamofire

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
        
        requestTrackRecords()
    }
    
    private func formatElaspsedTime(_ time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func requestTrackRecords() {
        AF.request("http://localhost:8080/tracks/\(Int(trackId))/records?page=\(currentPage)", method: .get)
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
        return 2;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return trackRecords.count
        } else {
            return 1;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rankingCell", for: indexPath)
        switch indexPath.section {
        case 0:
            let record = trackRecords[indexPath.row]
            cell.textLabel?.text = "\(indexPath.row + 1). \(formatElaspsedTime(record.time))"
            cell.textLabel?.textAlignment = .left
            cell.isHidden = false
            break
        case 1:
            cell.textLabel?.text = "더 보기"
            cell.textLabel?.textAlignment = .center
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
        currentPage += 1
        requestTrackRecords()
        let cell = tableView.dequeueReusableCell(withIdentifier: "rankingCell", for: indexPath)
    }
}





