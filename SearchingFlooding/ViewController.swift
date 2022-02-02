//
//  ViewController.swift
//  SearchingFlooding
//
//  Created by Pawan Kumar on 01/02/22.
//

import UIKit

let NEWS_API_Key = ""

class UserSearchViewController: UIViewController  {
    
    // MARK: IBOutlets
    // MARK:
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    private var userLoader: UserLoader = UserLoader(sesssion: URLSession.shared)
    
    var articles: [Article] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.searchBar.delegate = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.userLoader = UserLoader(sesssion: URLSession.shared)
    }

}


extension UserSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      let task =   userLoader.loadUsers(matching: searchText) { [weak self] result in
                   switch result {
                   case .success(let articles):
                       self?.articles = articles
                       DispatchQueue.main.async {
                           self?.tableView.reloadData()
                       }
                   case .failure(let error):
                       break
                   }
               }
        task.cancel()
    }
}


extension UserSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.detailTextLabel?.text = articles[indexPath.row].title
        cell.textLabel?.text = articles[indexPath.row].title
        
        return cell
    }
    
}


class UserLoader {
    private let urlSession: URLSession
    private weak var currentTask: URLSessionDataTask?
    
    
    init(sesssion: URLSession) {
        self.urlSession = sesssion
    }

    func loadUsers(matching query: String, completionHandler: @escaping (Result<[Article],PKError>) -> Void) -> URLSessionDataTask {
        let url = requestURL(forQuery: query)
        let task = self.urlSession.dataTask(with: url) { (data, _,error) in
            switch (data,error) {
            case(_ , let error?):
                completionHandler(.failure(PKError(message: error.localizedDescription)))
            case (let data?,_):
                do {
                    let articles: [Article] = try self.unbox(data: data)
                    completionHandler(.success(articles))
                } catch  {
                    completionHandler(.failure(PKError(message: error.localizedDescription)))
                }
            case (.none, .none):
                completionHandler(.failure(PKError(message: "fsfsdfsdf")))
            }
        }
        
        task.resume()
        
        return task
    }
    
    
    private func unbox(data: Data) throws -> [Article] {
        var articles: [Article] = []
        do {
            let news = try JSONDecoder().decode(News.self, from: data)
            articles = news.articles ?? []
            return articles
        } catch {
            print("Something Went Wrong: \(error.localizedDescription)")
        }
        
        return articles
    }


    private func requestURL(forQuery query: String) -> URL {
        return URL(string: "https://newsapi.org/v2/everything?q=\(query)&from=2022-01-01&sortBy=publishedAt&apiKey=\(NEWS_API_Key)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
}
}


struct News: Codable {
    let status: String?
    let totalResults: Int?
    let articles: [Article]?
}

// MARK: - Article
struct Article: Codable {
    //let source: Source
    let author: String?
    let title, articleDescription: String?
   // let url: String
 //   let urlToImage: String
    //let publishedAt: Date
    let content: String?

//    enum CodingKeys: String, CodingKey {
//        case  author, title
//        case articleDescription = "description"
//        case url, content
//    }
}

// MARK: - Source
struct Source: Codable {
    let id: String?
    let name: String
}


struct PKError: Error {
    var message: String
    
}
