function New-MainViewModel {
    $list = New-Object 'System.Collections.ObjectModel.ObservableCollection[Object]'
    return [PSCustomObject]@{
        SoftwareAppList = $list
    }
}