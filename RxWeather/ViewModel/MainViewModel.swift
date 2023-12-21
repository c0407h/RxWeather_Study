//
//  Mastering RxSwift
//  Copyright (c) KxCoding <help@kxcoding.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import NSObject_Rx

typealias SectionModel = AnimatableSectionModel<Int, WeatherData>

class MainViewModel: HasDisposeBag {
    init(title: String, sceneCoordinator: SceneCoordinatorType, weatherApi: WeatherApiType, locationProvider: LocationProviderType) {
        self.title = BehaviorRelay(value: title)
        self.sceneCoordinator = sceneCoordinator
        self.weatherApi = weatherApi
        self.locationProvider = locationProvider
        
        
        //위치가 업데이트 될때마다 타이틀 속성을 통해 새로운 주소 방출
        locationProvider.currentAddress()
            .bind(to: self.title)
            .disposed(by: disposeBag)
        
    }
    
    static let tempFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "Ko_kr")
        return formatter
    }()
    
    //주소바인딩할 때 사용
    let title: BehaviorRelay<String>
    
    //의존성과 관련된 속성 추가
    let sceneCoordinator: SceneCoordinatorType
    let weatherApi: WeatherApiType
    let locationProvider: LocationProviderType
    
    //tableView와 바인딩할 Observable생성, 항상 tableview와 바인딩 할 것이기 때문에 Driver로 생성
    var weatherData: Driver<[SectionModel]> {
        //RxDataSource를 사용하기 위해서 SectionModel로 선언
        return locationProvider.currentLocation() // currentLocation()이 리턴하는 Observable은 CLLocation 객체를 방출함
            .flatMap { [unowned self] in
                //api객체에서 fetch 메소드 호출
                self.weatherApi.fetch(location: $0) //Driver로 변경
                    .asDriver(onErrorJustReturn: (nil, [WeatherDataType]()))
            }
            .map{ (summary, forecast) in //전달된 배열을 SectionModel 배열로 변환
                var summaryList = [WeatherData]()
                if let summary = summary as? WeatherData {
                    summaryList.append(summary)
                }
                //테이블뷰에는 두개의 섹션이 표시됨 첫번째 섹션에는 현재날씨, 두번째 섹션에는 예보목록 리턴시 섹션 모델 배열을 리턴
                return [
                    SectionModel(model: 0, items: summaryList),
                    SectionModel(model: 1, items: forecast as! [WeatherData])
                ]
            }
            .asDriver(onErrorJustReturn: [])
    }
    
    //tableView에서 사용할 dataSource 선언
    let dataSource: RxTableViewSectionedAnimatedDataSource<SectionModel> = {
        let ds = RxTableViewSectionedAnimatedDataSource<SectionModel> { (dataSource, tableView, indexPath, data) -> UITableViewCell in
            //indexPath의 section으로 분기
            switch indexPath.section {
            case 0:
                //summary TableviewCell에 현재 날씨 표시
                let cell = tableView.dequeueReusableCell(withIdentifier: SummaryTableViewCell.identifier, for: indexPath) as! SummaryTableViewCell
                cell.configure(from: data, tempFormatter: MainViewModel.tempFormatter)
                
                return cell
            default :
                let cell = tableView.dequeueReusableCell(withIdentifier: ForecastTableViewCell.identifier, for: indexPath) as! ForecastTableViewCell
                
                cell.configure(from: data, dateFormatter: MainViewModel.dateFormatter, tempFormatter: MainViewModel.tempFormatter)
                return cell
            }
        }
        return ds
    }()
    
}
