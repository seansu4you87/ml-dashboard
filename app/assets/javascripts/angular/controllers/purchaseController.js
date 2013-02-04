function purchaseController($scope, $http) {
  
  $scope.success = "Waiting"

  $scope.getPurchaseData = function () {

    $http({
      method: 'GET',
      url: 'http://localhost:3000/purchases.json'
    }).
    success(function (data) {

      $scope.data = data
      $scope.success = "Yes"

    }).
    error(function (data, status) {

      $scope.success = "No"
      $scope.error = status

    });
  };

  $scope.getPurchaseData();

}