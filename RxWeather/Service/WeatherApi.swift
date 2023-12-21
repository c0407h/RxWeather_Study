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
import CoreLocation
import NSObject_Rx


//Api 처리 class
class OpenWeatherMapApi: NSObject, WeatherApiType {
    //현재 날씨 방출 UI Binding에 활용하기 때문에 BehaviorRelay로 선언
    private let summarRelay = BehaviorRelay<WeatherDataType?>(value: nil)
    //예고 목록 방출
    private let forecastRelay = BehaviorRelay<[WeatherDataType]>(value: [])
    
    //네트워크 처리에 사용할 UrlSession
    private let urlSession = URLSession.shared
    
    //현재 날씨를 가져오는 메소드
    //location을 파라메터로 받아 현재 날씨를 옵셔널 WeatherDataType로 방출하는 옵저버블을 리턴
    private func fetchSummary(location: CLLocation) -> Observable<WeatherDataType?> {
        let request = composeUrlRequest(endpoint: summaryEndpoint, from: location)
        
        return request
            .flatMap{ request in
                self.urlSession.rx.data(request: request)
            }
            .map{ data -> WeatherSummary in //옵저버블이 방출하는 바이너리 데이터에는 Json객체가 저장되어있음 JsonDecoder를 활용하여 weatherSummary형식으로 변환
                let decoder = JSONDecoder()
                return try decoder.decode(WeatherSummary.self, from: data)
            }
            .map { WeatherData(summary: $0) } //파싱한 데이터를 weahter형식으로 변환
            .catchAndReturn(nil) //에러가 발생한경우에는 nil을 방출
        
        
        //data task 처리
        //data 메소드는 요청을 전달한 다음 결과를 데이터 형식으로 방출하는 Observable을 리턴
//        return urlSession.rx.data(request: request)
//            .map{ data -> WeatherSummary in //옵저버블이 방출하는 바이너리 데이터에는 Json객체가 저장되어있음 JsonDecoder를 활용하여 weatherSummary형식으로 변환
//                let decoder = JSONDecoder()
//                return try decoder.decode(WeatherSummary.self, from: data)
//            }
//            .map { WeatherData(summary: $0) } //파싱한 데이터를 weahter형식으로 변환
//            .catchErrorJustReturn(nil) //에러가 발생한경우에는 nil을 방출
    }

    //예보 데이터를 요청하는 메소드
    private func fetchForecast(location: CLLocation) -> Observable<[WeatherDataType]> {
        let request = composeUrlRequest(endpoint: forecastEndpoint, from: location)
        
//        return urlSession.rx.data(request: request)
//            .map { data -> [WeatherData] in
//                let decoder = JSONDecoder()
//                let forecast = try decoder.decode(Forecast.self, from: data)
//                return forecast.list.map(WeatherData.init)
//            }
//            .catchAndReturn([])
        
        return request
            .flatMap{ request in
                self.urlSession.rx.data(request: request)
            }
            .map { data -> [WeatherData] in
                let decoder = JSONDecoder()
                let forecast = try decoder.decode(Forecast.self, from: data)
                return forecast.list.map(WeatherData.init)
            }
            .catchAndReturn([])
    }
    
    
    
    
    @discardableResult
    func fetch(location: CLLocation) -> RxSwift.Observable<(WeatherDataType?, [WeatherDataType])> {
        //두 메소드가 리턴하는 Observable을 상수에 저장
        let summary = fetchSummary(location: location)
        let forecast = fetchForecast(location: location)
        
        Observable.zip(summary, forecast)//이렇게 하면 모든 옵저버블이 결과를 방출하는 시점에 최종 구독자로 하나의 결과가 전달됨
            .subscribe(onNext:{ [weak self] result in
                //여기에는 inner Observable이 방출한 요소가 튜플로 전달됨
                //튜플의 첫번째 요소를 summaryRelay로 전달
                self?.summarRelay.accept(result.0)
                //두번째 요소는 forecastRelay에 전달
                self?.forecastRelay.accept(result.1)
            })
            .disposed(by: rx.disposeBag)


        //두 Relay를 Observable로 바꾼뒤 combineLatest로 결합해서 리턴
        return Observable.combineLatest(summarRelay.asObservable(), forecastRelay.asObservable())
        
    }
    
    
}


