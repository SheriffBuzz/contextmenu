#Include %A_LineFile%\..\ModelList.ahk
/*
    Model

    Generic container for an Object, with meta and util functions.
*/
class ModelClass {
    __New() {
        this["$Metadata$"]:= {} 
    }
    
    getMetadata() {
        return this["$Metadata$"]
    }

    getMetadataValue(metadataProp) {
        return this["$Metadata$"][metadataProp]
    }

    setMetadata(ByRef metadata) {
        this["$Metadata$"]:= metadata
    }

    /*
        sets a property on an object's metadata.
        @param prop - property to set on metadata
        @param val - value to set. if blank, defaults to 1.
    */
    setMetadataFlag(prop, val="") {
        this.getMetadata()[prop]:= (val) ? val : 1
    }

    /*
        applyDefaults - apply properties from another object on the current model
        @param defaults
    */
    applyDefaults(ByRef defaults) {
        if (!IsObject(defaults)) {
            return
        }
        for key, val in defaults {
            sourceVal:= this[key]
            if (sourceVal = "") {
                this[key]:= val
            }
        }
    }
}
