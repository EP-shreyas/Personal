import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import DOCUMENT_TRACKER from '@salesforce/schema/Document__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getDocumentTypeList from '@salesforce/apex/UploadFileController.getDocumentTypeList';
import getDocumentTypeOnRecordTypeList from '@salesforce/apex/UploadFileController.getDocumentTypeOnRecordTypeList';

export default class UploadFileFuntionality extends NavigationMixin(LightningElement) {
    @api recordId;
    @api headerDisplay;
    @api documentTypeDefault;
    @api deviceName;
    @api isDocumentTypeDisabled;
    keyIndex = 0;
    displayDataTable = false;
    generalURL;
    @api objectApiName;
    MAX_FILE_SIZE = 26214400;

    url;
    @wire(getObjectInfo, { objectApiName: DOCUMENT_TRACKER })
    documentTrackerInfo;
    /* @wire(getPicklistValues,
    {
        recordTypeId: '$documentTrackerInfo.data.defaultRecordTypeId',
        fieldApiName: documentType
    }
    )*/
    options;


    @track itemListToUpdate = [];
    @track itemListToDisplay = [
        /*  {
            documentType: '',
            documentId: '',
            documentName:'',
            id: ++this.keyIndex
        }*/
    ];

    @track itemList = [
        {

            documentType: this.documentTypeDefault,
            documentId: '',
            id: ++this.keyIndex
        }
    ];
    value;

    @wire(getDocumentTypeOnRecordTypeList, { recordId: '$recordId', objectApiName: '$objectApiName' })
    wiredDocumentTypeOnRecordTypeList(value) {
        let options = [];

        const { data, error } = value;
        if (data) {
            data.forEach(r => {
                options.push({
                    label: r,
                    value: r,
                });
            });
        }
        this.options = options;

        if (error) {
            this.error = error;
        }
    }




    connectedCallback() {
        this.generalURL = {
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        };
        this[NavigationMixin.GenerateUrl](this.generalURL).then(
            (url) => (this.url = url)
        );

        this.itemList = [
            {
                documentType: this.documentTypeDefault,
                documentId: '',
                id: ++this.keyIndex
            }]

    }

    handleChange(event) {
        if (event.target.name == 'Document') {
            this.itemList[event.currentTarget.dataset.index].documentType = event.target.value;
            let foundElement = this.itemListToDisplay.find(ele => ele.id == this.itemList[event.currentTarget.dataset.index].documentId);
            if (foundElement !== undefined) {
                foundElement.documentType = event.target.value;
                this.itemListToDisplay = [...this.itemListToDisplay];
            } else {
                foundElement = this.itemListToDisplay.filter(x => this.itemListToUpdate.some(y => y.id === x.id));
                for (let i = 0; i < foundElement.length; i++) {
                    if (foundElement[i].documentType == '') {
                        foundElement[i].documentType = event.target.value;
                        this.itemListToDisplay = [...this.itemListToDisplay];
                    }
                }
            }


            /*  let foundElement = this.itemListToDisplay.filter(x => !this.itemListToUpdate.some(y => y.id === x.id));
            console.log('foundElement1:',foundElement.length)
            if(foundElement !== undefined){
            foundElement.documentType = event.target.value;
            this.itemListToDisplay = [...this.itemListToDisplay];
            }
        */

        }
    }
    handleAddRow() {
        let objRow = {
            /*documentType: ''*/
            documentType: this.itemList[0].documentType, //To make Added Document type same as Before used Document Type
            documentId: '',
            id: ++this.keyIndex
        }
        this.itemList = [...this.itemList, Object.create(objRow)];
    }
    /* addRow() {
    ++this.keyIndex;
    var newItem = [{ id: this.keyIndex }];
    this.itemList = this.itemList.concat(newItem);
    }*/
    handleSave(itemListToUpdateOrInsert, deleteOrInsert) {
        console.log(deleteOrInsert);
        console.log(JSON.stringify(itemListToUpdateOrInsert));
        getDocumentTypeList({
            jsonString: JSON.stringify(itemListToUpdateOrInsert),
            filesToBeDeleted: this.contentDocumentIds,
            onSave: deleteOrInsert
        }).then(result => {
            if (deleteOrInsert) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record Stored Successfully: ',
                        variant: 'Success',
                    }),
                );
            }
            /*  if(this.deviceName =='PHONE'){
                  this[NavigationMixin.Navigate]({
                      type: 'standard__recordPage',
                      attributes: {
                          recordId: this.recordId,
                          actionName: 'view'
                      }
                      });
              }*/
            if (this.url == null || this.url == undefined || this.url == "") {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        actionName: 'view'
                    }
                });
            } else {
                window.open(this.url, "_self");
            }

        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: error.body.message,
                    variant: 'error'
                }),
            );
        })


    }
    handleCancel() {
        if (this.itemListToDisplay.length > 0) {
            this.handleSave(this.itemListToDisplay, false);
        } else if (this.itemList.length > 0) {
            this.handleSave(this.itemList, false);
        }

    }
    contentDocumentIds = [];
    handleDeleteRow(event) {
        this.contentDocumentIds.push(event.currentTarget.dataset.index);
        this.itemListToDisplay = this.itemListToDisplay.filter(value => value.id !== event.currentTarget.dataset.index);
        if (this.itemListToDisplay.length > 0) {
            this.displayDataTable = true;

        } else {
            this.displayDataTable = false;
        }
    }

    handleClick() {

        if (this.itemList.length > 0) {
            /*      for(let i = 0; i < this.itemList.length; i++) {
                if(this.itemList[i].documentId != '')
                if(this.itemListToUpdate.length >0){
                this.itemListToUpdate = [...this.itemListToUpdate, this.itemList[i]];
                }else{
                    this.itemListToUpdate.push(this.itemList) 
                }
            
                //  this.itemListToUpdate.push(this.itemList);
                }*/

        }
        if (this.itemListToDisplay.length > 0) {
            this.handleSave(this.itemListToDisplay, true);

            /*   getDocumentTypeList({
                jsonString : JSON.stringify(this.itemListToDisplay),
                filesToBeDeleted : this.contentDocumentIds,
                onSave : true
            }).then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record Stored Successfully: ',
                        variant: 'success',
                    }),
                );
            
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: error.body.message,
                        variant: 'error'
                    }),
                );
            })
            
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });*/

        }
    }
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.csv', '.xlsx', '.xlsm', '.docx', '.txt'];
    }
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;

        let uploadedFileNames = '';
        this.displayDataTable = true;
        for (let i = 0; i < uploadedFiles.length; i++) {
            uploadedFileNames += uploadedFiles[i].name + ', ';
            if (event.target.name == 'fileUploader') {
                if (uploadedFiles.length == 1) {
                    if (this.itemList[event.currentTarget.dataset.index].documentId == '') {
                        this.itemList[event.currentTarget.dataset.index].documentId = uploadedFiles[i].documentId;

                        let objRow1 = {
                            documentType: this.itemList[event.currentTarget.dataset.index].documentType,
                            documentId: uploadedFiles[i].documentId,
                            documentName: uploadedFiles[i].name,
                            id: uploadedFiles[i].documentId
                        }

                        this.itemListToDisplay.push(objRow1);

                    } else {
                        let objRow1 = {
                            documentType: this.itemList[event.currentTarget.dataset.index].documentType,
                            documentId: uploadedFiles[i].documentId,
                            documentName: uploadedFiles[i].name,
                            id: uploadedFiles[i].documentId
                        }
                        this.itemListToUpdate.push(objRow1);
                        this.itemListToDisplay.push(objRow1)

                    }

                    // this.itemList[event.currentTarget.dataset.index].documentName = uploadedFiles[i].name;
                } else {
                    let objRow1 = {
                        documentType: this.itemList[event.currentTarget.dataset.index].documentType,
                        documentId: uploadedFiles[i].documentId,
                        documentName: uploadedFiles[i].name,
                        id: uploadedFiles[i].documentId
                    }
                    this.itemListToUpdate.push(objRow1);
                    this.itemListToDisplay.push(objRow1);


                }
                console.log('testt')

            }
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' Files uploaded Successfully: ' + uploadedFileNames,
                variant: 'success',
            }),
        );
    }
}