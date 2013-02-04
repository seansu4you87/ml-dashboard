window.MLDashboardApp = angular.module('MLDashboard', ['ngResource']);

class PurchaseController
  constructor: ($scope, $http) ->
    $scope.success = "Waiting"

    $scope.getPurchaseData = (page = 1) ->
      $http(
        method: 'GET'
        url:    "http://localhost:3000/purchases.json?page=#{page}"
      ).
      success((data) ->
        $scope.data = data
        $scope.success = "Yes"
      ).
      error((data, status) ->
        $scope.success = "No"
        $scope.error = status
      )

    $scope.getPurchaseData()

@PurchaseController = PurchaseController

MLDashboardApp.directive('mlVisualization', ->
  restrict: 'E'
  terminal: true
  link: (scope, element, attrs) ->
    console.log element
)