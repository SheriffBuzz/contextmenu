/*
    ModelList

    Class to wrap arr of models
*/
class ModelList {
    __New(ByRef modelList) {
        this.list:= modelList
    }

    findFirstErrorModel() {
        for i, model in this.list {
            if (model.error) {
                return model
            }
        }
    }

    /*
        hasModelWithMetadataFlag

        Returns boolean if model has some prop in its metadata object that has non empty value
    */
    hasModelWithMetadataFlag(metadataProp) {
        for i, model in this.list {
            if (model.getMetadata()[metadataProp] != "") {
                return true
            }
        }
        return false
    }

    /*
        getMetadataListByProperty

        Returns an arr of values, for all models that have that metadata property
        Remarks - returns non empty values only
    */
    getMetadataByProperty(metadataProp) {
        propList:= []
        for i, model in this.list {
            val:= model.getMetadata()[metadataProp]
            if (val != "") {
                propList.push(val)
            }
        }
        return propList
    }
}
