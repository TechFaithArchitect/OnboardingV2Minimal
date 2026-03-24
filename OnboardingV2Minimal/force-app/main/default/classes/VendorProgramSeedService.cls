/**
 * Data seed for blank sandboxes / production gaps: vendors, Vendor_Customization__c, agreements, credentials,
 * training, and Vendor_Program_Requirement__c. PerfectVision Chuzo programs use PV_PROGRAM_BASE_* refs with
 * OnboardV2-aligned requirement lists in getVendorProgramRequirementRowsByProgramRef(); other refs use defaults.
 */
public with sharing class VendorProgramSeedService {
    public class Options {
        public Boolean dryRun = false;
        public Boolean updateExistingVendorActiveFlag = true;
        public Boolean strictPicklists = false;
        public Boolean skipRowsWithMissingContractType = false;
        public Boolean seedContractRecordTypeReferences = true;
        public Boolean seedAgreementTypeAndTemplateRecords = true;
        public Boolean seedTrainingSystems = true;
        public Boolean seedTrainingRequirements = true;
        public Boolean seedVendorProgramRequirements = true;
        public Boolean cleanupDuplicates = false;
        public Set<String> vendorNames = new Set<String>();
    }

    public class Result {
        public Integer vendorsInserted = 0;
        public Integer vendorsUpdated = 0;
        public Integer contractRefsInserted = 0;
        public Integer contractRefsUpdated = 0;
        public Integer customizationsInserted = 0;
        public Integer customizationsUpdated = 0;
        public Integer customizationsSkipped = 0;
        public Integer agreementTypesInserted = 0;
        public Integer agreementTemplatesInserted = 0;
        public Integer agreementLinksUpdated = 0;
        public Integer agreementLinksSkipped = 0;
        public Integer credentialTypesInserted = 0;
        public Integer credentialTypesUpdated = 0;
        public Integer requiredCredentialsInserted = 0;
        public Integer requiredCredentialsUpdated = 0;
        public Integer dependencyRowsInserted = 0;
        public Integer duplicateSeedRowsSkipped = 0;
        public Integer duplicateExistingRowsDetected = 0;
        public Integer cleanupRowsUpdated = 0;
        public Integer cleanupRowsDeleted = 0;
        public Integer trainingSystemsInserted = 0;
        public Integer trainingSystemsUpdated = 0;
        public Integer trainingRequirementsInserted = 0;
        public Integer trainingRequirementsUpdated = 0;
        public Integer vendorProgramRequirementsInserted = 0;
        public Integer vendorProgramRequirementsUpdated = 0;
        public List<String> warnings = new List<String>();

        public void mergeFrom(Result other) {
            if (other == null) return;
            vendorsInserted += other.vendorsInserted;
            vendorsUpdated += other.vendorsUpdated;
            contractRefsInserted += other.contractRefsInserted;
            contractRefsUpdated += other.contractRefsUpdated;
            customizationsInserted += other.customizationsInserted;
            customizationsUpdated += other.customizationsUpdated;
            customizationsSkipped += other.customizationsSkipped;
            agreementTypesInserted += other.agreementTypesInserted;
            agreementTemplatesInserted += other.agreementTemplatesInserted;
            agreementLinksUpdated += other.agreementLinksUpdated;
            agreementLinksSkipped += other.agreementLinksSkipped;
            credentialTypesInserted += other.credentialTypesInserted;
            credentialTypesUpdated += other.credentialTypesUpdated;
            requiredCredentialsInserted += other.requiredCredentialsInserted;
            requiredCredentialsUpdated += other.requiredCredentialsUpdated;
            dependencyRowsInserted += other.dependencyRowsInserted;
            duplicateSeedRowsSkipped += other.duplicateSeedRowsSkipped;
            duplicateExistingRowsDetected += other.duplicateExistingRowsDetected;
            cleanupRowsUpdated += other.cleanupRowsUpdated;
            cleanupRowsDeleted += other.cleanupRowsDeleted;
            trainingSystemsInserted += other.trainingSystemsInserted;
            trainingSystemsUpdated += other.trainingSystemsUpdated;
            trainingRequirementsInserted += other.trainingRequirementsInserted;
            trainingRequirementsUpdated += other.trainingRequirementsUpdated;
            vendorProgramRequirementsInserted += other.vendorProgramRequirementsInserted;
            vendorProgramRequirementsUpdated += other.vendorProgramRequirementsUpdated;
            warnings.addAll(other.warnings);
        }

        public String summary() {
            return JSON.serialize(this);
        }
    }

    public static Result runAll() {
        return runAll(new Options());
    }

    public static Result runAll(Options inputOptions) {
        Options options = normalizeOptions(inputOptions);
        Result out = new Result();
        out.mergeFrom(seedProgramsAndAgreements(options));
        out.mergeFrom(seedVendorProgramRequirements(options));
        out.mergeFrom(seedCredentialData(options));
        out.mergeFrom(seedTrainingSystems(options));
        out.mergeFrom(seedTrainingRequirements(options));
        return out;
    }

    public static Result seedProgramsAndAgreements() {
        return seedProgramsAndAgreements(new Options());
    }

    public static Result seedProgramsAndAgreements(Options inputOptions) {
        Options options = normalizeOptions(inputOptions);
        Result out = new Result();

        Map<String, Boolean> vendorActiveMap = getVendorActiveByName();
        List<List<String>> contractReferenceRows = dedupeContractReferenceRows(getContractReferenceRows(), out);
        List<List<Object>> programRows = dedupeProgramRowsByRef(getProgramRows(), out);
        List<List<String>> agreementRows = dedupeAgreementRows(getAgreementRows(), out);

        Set<String> selectedVendors = normalizeVendorNames(options.vendorNames);
        Boolean hasFilter = !selectedVendors.isEmpty();

        List<List<Object>> scopedProgramRows = new List<List<Object>>();
        Set<String> scopedProgramRefs = new Set<String>();
        for (List<Object> row : programRows) {
            String ref = (String) row[0];
            String vendorName = (String) row[1];
            if (!hasFilter || selectedVendors.contains(vendorName)) {
                scopedProgramRows.add(row);
                scopedProgramRefs.add(ref);
            }
        }

        List<List<String>> scopedAgreementRows = new List<List<String>>();
        for (List<String> row : agreementRows) {
            if (scopedProgramRefs.contains(row[0])) scopedAgreementRows.add(row);
        }

        if (scopedProgramRows.isEmpty()) {
            out.warnings.add('No program rows matched vendorNames filter.');
        }

        Set<String> vendorNames = new Set<String>();
        if (hasFilter) vendorNames.addAll(selectedVendors);
        else vendorNames.addAll(vendorActiveMap.keySet());
        for (List<Object> row : scopedProgramRows) vendorNames.add((String) row[1]);

        Map<String, Vendor__c> vendorByName = new Map<String, Vendor__c>();
        if (!vendorNames.isEmpty()) {
            for (Vendor__c v : [SELECT Id, Name, Active__c FROM Vendor__c WHERE Name IN :vendorNames]) {
                vendorByName.put(v.Name, v);
            }
        }

        List<Vendor__c> vendorInserts = new List<Vendor__c>();
        for (String vn : vendorNames) {
            if (!vendorByName.containsKey(vn)) {
                Boolean active = vendorActiveMap.containsKey(vn) ? vendorActiveMap.get(vn) : true;
                vendorInserts.add(new Vendor__c(Name = vn, Active__c = active));
            }
        }

        if (!vendorInserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(vendorInserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.vendorsInserted++;
                else out.warnings.add('Vendor insert failed ' + vendorInserts[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.vendorsInserted = vendorInserts.size();
        }

        vendorByName.clear();
        if (!vendorNames.isEmpty()) {
            for (Vendor__c v : [SELECT Id, Name, Active__c FROM Vendor__c WHERE Name IN :vendorNames]) {
                vendorByName.put(v.Name, v);
            }
        }

        if (options.updateExistingVendorActiveFlag) {
            List<Vendor__c> vendorUpdates = new List<Vendor__c>();
            for (String vn : vendorActiveMap.keySet()) {
                if (hasFilter && !selectedVendors.contains(vn)) continue;
                Vendor__c v = vendorByName.get(vn);
                if (v != null && v.Active__c != vendorActiveMap.get(vn)) {
                    v.Active__c = vendorActiveMap.get(vn);
                    vendorUpdates.add(v);
                }
            }

            if (!vendorUpdates.isEmpty() && !options.dryRun) {
                Database.SaveResult[] srs = Database.update(vendorUpdates, false);
                for (Integer i = 0; i < srs.size(); i++) {
                    if (srs[i].isSuccess()) out.vendorsUpdated++;
                    else out.warnings.add('Vendor update failed ' + vendorUpdates[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
                }
            } else {
                out.vendorsUpdated = vendorUpdates.size();
            }
        }

        Map<String, String> contractDevByName = new Map<String, String>();
        for (List<String> row : contractReferenceRows) contractDevByName.put(row[0], row[1]);

        Set<String> neededContractNames = new Set<String>();
        Set<String> neededContractDevs = new Set<String>();
        for (List<Object> row : scopedProgramRows) {
            String contractName = (String) row[2];
            if (String.isBlank(contractName)) continue;
            neededContractNames.add(contractName);
            String devName = contractDevByName.get(contractName);
            if (!String.isBlank(devName)) neededContractDevs.add(devName);
            else out.warnings.add('No contract mapping configured for ' + contractName);
        }

        if (options.seedContractRecordTypeReferences && !neededContractNames.isEmpty()) {
            Map<String, Contract_Record_Type_Reference__c> refByName = new Map<String, Contract_Record_Type_Reference__c>();
            Map<String, Contract_Record_Type_Reference__c> refByDev = new Map<String, Contract_Record_Type_Reference__c>();
            for (Contract_Record_Type_Reference__c ref : [
                SELECT Id, Name, Developer_Name__c, RecordTypeId__c
                FROM Contract_Record_Type_Reference__c
                WHERE Name IN :neededContractNames OR Developer_Name__c IN :neededContractDevs
            ]) {
                if (!refByName.containsKey(ref.Name)) refByName.put(ref.Name, ref);
                if (!String.isBlank(ref.Developer_Name__c) && !refByDev.containsKey(ref.Developer_Name__c)) refByDev.put(ref.Developer_Name__c, ref);
            }

            Map<String, Id> rtByName = new Map<String, Id>();
            Map<String, Id> rtByDev = new Map<String, Id>();
            for (RecordType rt : [
                SELECT Id, Name, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'Contract'
                AND (Name IN :neededContractNames OR DeveloperName IN :neededContractDevs)
            ]) {
                if (!rtByName.containsKey(rt.Name)) rtByName.put(rt.Name, rt.Id);
                if (!rtByDev.containsKey(rt.DeveloperName)) rtByDev.put(rt.DeveloperName, rt.Id);
            }

            List<Contract_Record_Type_Reference__c> refInserts = new List<Contract_Record_Type_Reference__c>();
            List<Contract_Record_Type_Reference__c> refUpdates = new List<Contract_Record_Type_Reference__c>();

            for (String contractName : neededContractNames) {
                String devName = contractDevByName.get(contractName);
                Contract_Record_Type_Reference__c existing = refByName.get(contractName);
                if (existing == null && !String.isBlank(devName)) existing = refByDev.get(devName);

                Id rtId = rtByName.get(contractName);
                if (rtId == null && !String.isBlank(devName)) rtId = rtByDev.get(devName);
                String rtIdTxt = rtId == null ? null : String.valueOf(rtId);
                if (rtId == null) out.warnings.add('No Contract RecordType found for ' + contractName + ' / ' + devName);

                if (existing == null) {
                    Contract_Record_Type_Reference__c nr = new Contract_Record_Type_Reference__c(Name = contractName);
                    if (!String.isBlank(devName)) nr.Developer_Name__c = devName;
                    if (!String.isBlank(rtIdTxt)) nr.RecordTypeId__c = rtIdTxt;
                    refInserts.add(nr);
                } else {
                    Boolean changed = false;
                    if (!String.isBlank(devName) && existing.Developer_Name__c != devName) {
                        existing.Developer_Name__c = devName;
                        changed = true;
                    }
                    if (!String.isBlank(rtIdTxt) && existing.RecordTypeId__c != rtIdTxt) {
                        existing.RecordTypeId__c = rtIdTxt;
                        changed = true;
                    }
                    if (changed) refUpdates.add(existing);
                }
            }

            if (!refInserts.isEmpty() && !options.dryRun) {
                Database.SaveResult[] srs = Database.insert(refInserts, false);
                for (Integer i = 0; i < srs.size(); i++) {
                    if (srs[i].isSuccess()) out.contractRefsInserted++;
                    else out.warnings.add('Contract ref insert failed ' + refInserts[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
                }
            } else {
                out.contractRefsInserted = refInserts.size();
            }

            if (!refUpdates.isEmpty() && !options.dryRun) {
                Database.SaveResult[] srs = Database.update(refUpdates, false);
                for (Integer i = 0; i < srs.size(); i++) {
                    if (srs[i].isSuccess()) out.contractRefsUpdated++;
                    else out.warnings.add('Contract ref update failed ' + refUpdates[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
                }
            } else {
                out.contractRefsUpdated = refUpdates.size();
            }
        }

        Map<String, Id> contractByName = new Map<String, Id>();
        Map<String, Id> contractByDev = new Map<String, Id>();
        if (!neededContractNames.isEmpty()) {
            for (Contract_Record_Type_Reference__c ref : [
                SELECT Id, Name, Developer_Name__c
                FROM Contract_Record_Type_Reference__c
                WHERE Name IN :neededContractNames OR Developer_Name__c IN :neededContractDevs
            ]) {
                if (!contractByName.containsKey(ref.Name)) contractByName.put(ref.Name, ref.Id);
                if (!String.isBlank(ref.Developer_Name__c) && !contractByDev.containsKey(ref.Developer_Name__c)) contractByDev.put(ref.Developer_Name__c, ref.Id);
            }
        }

        Set<String> validRetail = new Set<String>();
        for (Schema.PicklistEntry e : Vendor_Customization__c.Retail_Option__c.getDescribe().getPicklistValues()) {
            if (e.isActive()) validRetail.add(e.getValue());
        }

        Set<String> validBusiness = new Set<String>();
        for (Schema.PicklistEntry e : Vendor_Customization__c.Business_Vertical__c.getDescribe().getPicklistValues()) {
            if (e.isActive()) validBusiness.add(e.getValue());
        }

        Set<Id> vendorIds = new Set<Id>();
        for (Vendor__c v : vendorByName.values()) vendorIds.add(v.Id);

        Map<String, List<Vendor_Customization__c>> existingByKey = new Map<String, List<Vendor_Customization__c>>();
        if (!vendorIds.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Contract_Record_Type__c, Label__c, Retail_Option__c, Business_Vertical__c,
                       General_Liability_Insurance_Needed__c, Auto_Insurance_Needed__c, Certificate_Holder_Needed__c,
                       Order_Entry_Platform__c
                FROM Vendor_Customization__c
                WHERE Vendor__c IN :vendorIds
            ]) {
                String key = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c)
                    + '|' + String.valueOf(vc.Label__c);
                if (!existingByKey.containsKey(key)) existingByKey.put(key, new List<Vendor_Customization__c>());
                existingByKey.get(key).add(vc);
            }
        }

        Map<String, String> keyByProgramRef = new Map<String, String>();
        List<Vendor_Customization__c> programInserts = new List<Vendor_Customization__c>();
        List<Vendor_Customization__c> programUpdates = new List<Vendor_Customization__c>();
        Map<String, Integer> plannedProgramCountByKey = new Map<String, Integer>();
        for (String existingKey : existingByKey.keySet()) {
            plannedProgramCountByKey.put(existingKey, existingByKey.get(existingKey).size());
        }

        for (List<Object> row : scopedProgramRows) {
            String ref = (String) row[0];
            String vendorName = (String) row[1];
            String contractName = (String) row[2];
            String label = (String) row[3];
            String retail = (String) row[4];
            String business = (String) row[5];
            Boolean gl = (Boolean) row[6];
            Boolean ai = (Boolean) row[7];
            Boolean ch = (Boolean) row[8];
            Boolean oep = (Boolean) row[9];
            Integer copies = (Integer) row[10];
            if (copies == null || copies < 1) copies = 1;

            Vendor__c v = vendorByName.get(vendorName);
            if (v == null) {
                out.customizationsSkipped++;
                out.warnings.add('Skip VC vendor missing ' + vendorName);
                continue;
            }

            Id contractId;
            if (!String.isBlank(contractName)) {
                contractId = contractByName.get(contractName);
                if (contractId == null) contractId = contractByDev.get(contractName);
                if (contractId == null && contractDevByName.containsKey(contractName)) {
                    contractId = contractByDev.get(contractDevByName.get(contractName));
                }
            }

            if (contractId == null && !String.isBlank(contractName)) {
                String msg = 'Missing Contract Ref ' + contractName + ' for ' + vendorName;
                if (options.skipRowsWithMissingContractType) {
                    out.customizationsSkipped++;
                    out.warnings.add('Skip ' + msg);
                    continue;
                }
                out.warnings.add(msg);
            }

            if (String.isBlank(label)) label = contractName;
            if (!String.isBlank(retail) && !validRetail.contains(retail)) {
                if (options.strictPicklists) {
                    out.customizationsSkipped++;
                    out.warnings.add('Skip invalid retail ' + retail);
                    continue;
                }
                retail = null;
            }

            if (!String.isBlank(business) && !validBusiness.contains(business)) {
                if (options.strictPicklists) {
                    out.customizationsSkipped++;
                    out.warnings.add('Skip invalid business ' + business);
                    continue;
                }
                business = null;
            }

            String key = String.valueOf(v.Id) + '|' + String.valueOf(contractId)
                + '|' + String.valueOf(retail) + '|' + String.valueOf(business)
                + '|' + String.valueOf(label);
            if (!keyByProgramRef.containsKey(ref)) {
                keyByProgramRef.put(ref, key);
            } else if (keyByProgramRef.get(ref) != key) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Duplicate programRef with conflicting definition: ' + ref + '. Keeping first row.');
            }

            List<Vendor_Customization__c> existing = existingByKey.containsKey(key)
                ? existingByKey.get(key)
                : new List<Vendor_Customization__c>();

            Integer alignCount = Math.min(copies, existing.size());
            for (Integer i = 0; i < alignCount; i++) {
                Vendor_Customization__c rec = existing[i];
                Boolean changed = false;
                if (rec.General_Liability_Insurance_Needed__c != gl) { rec.General_Liability_Insurance_Needed__c = gl; changed = true; }
                if (rec.Auto_Insurance_Needed__c != ai) { rec.Auto_Insurance_Needed__c = ai; changed = true; }
                if (rec.Certificate_Holder_Needed__c != ch) { rec.Certificate_Holder_Needed__c = ch; changed = true; }
                if (rec.Order_Entry_Platform__c != oep) { rec.Order_Entry_Platform__c = oep; changed = true; }
                if (changed) programUpdates.add(rec);
            }

            Integer plannedCount = plannedProgramCountByKey.containsKey(key) ? plannedProgramCountByKey.get(key) : existing.size();
            Integer toCreate = copies - plannedCount;
            if (toCreate < 0) toCreate = 0;
            for (Integer i = 0; i < toCreate; i++) {
                Vendor_Customization__c vc = new Vendor_Customization__c(
                    Vendor__c = v.Id,
                    Label__c = label,
                    General_Liability_Insurance_Needed__c = gl,
                    Auto_Insurance_Needed__c = ai,
                    Certificate_Holder_Needed__c = ch,
                    Order_Entry_Platform__c = oep
                );
                if (contractId != null) vc.Contract_Record_Type__c = contractId;
                if (!String.isBlank(retail)) vc.Retail_Option__c = retail;
                if (!String.isBlank(business)) vc.Business_Vertical__c = business;
                programInserts.add(vc);
            }
            plannedProgramCountByKey.put(key, plannedCount + toCreate);
        }

        if (!programInserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(programInserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.customizationsInserted++;
                else out.warnings.add('VC insert failed (' + programInserts[i].Label__c + '): ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.customizationsInserted = programInserts.size();
        }

        if (!programUpdates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(programUpdates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.customizationsUpdated++;
                else out.warnings.add('VC update failed (' + programUpdates[i].Id + '): ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.customizationsUpdated = programUpdates.size();
        }

        Map<String, List<Id>> programIdsByRef = new Map<String, List<Id>>();
        Map<String, List<Vendor_Customization__c>> rowsByKey = new Map<String, List<Vendor_Customization__c>>();
        Set<String> keys = new Set<String>(keyByProgramRef.values());
        if (!vendorIds.isEmpty() && !keys.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Contract_Record_Type__c, Label__c, Retail_Option__c, Business_Vertical__c
                FROM Vendor_Customization__c
                WHERE Vendor__c IN :vendorIds
                ORDER BY CreatedDate ASC
            ]) {
                String key = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c)
                    + '|' + String.valueOf(vc.Label__c);
                if (!keys.contains(key)) continue;
                if (!rowsByKey.containsKey(key)) rowsByKey.put(key, new List<Vendor_Customization__c>());
                rowsByKey.get(key).add(vc);
            }
        }

        for (String ref : keyByProgramRef.keySet()) {
            String key = keyByProgramRef.get(ref);
            List<Vendor_Customization__c> rows = rowsByKey.get(key);
            if (rows == null || rows.isEmpty()) {
                out.agreementLinksSkipped++;
                out.warnings.add('No VC for ref ' + ref);
                continue;
            }
            List<Id> ids = new List<Id>();
            for (Vendor_Customization__c vc : rows) ids.add(vc.Id);
            programIdsByRef.put(ref, ids);
        }

        Set<String> agreementNames = new Set<String>();
        Set<String> agreementTypeNames = new Set<String>();
        for (List<String> row : scopedAgreementRows) {
            if (!String.isBlank(row[1])) agreementNames.add(row[1]);
            if (!String.isBlank(row[2])) agreementTypeNames.add(row[2]);
        }

        Map<String, Id> agreementTypeIdByName = new Map<String, Id>();
        if (!agreementTypeNames.isEmpty()) {
            for (echosign_dev1__Agreement_Type__c t : [
                SELECT Id, Name, CreatedDate
                FROM echosign_dev1__Agreement_Type__c
                WHERE Name IN :agreementTypeNames
                ORDER BY Name ASC, CreatedDate ASC, Id ASC
            ]) {
                if (!agreementTypeIdByName.containsKey(t.Name)) {
                    agreementTypeIdByName.put(t.Name, t.Id);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate Agreement Type already exists for Name "' + t.Name + '". Using the first row.');
                }
            }
        }

        if (options.seedAgreementTypeAndTemplateRecords && !agreementTypeNames.isEmpty()) {
            List<echosign_dev1__Agreement_Type__c> typeInserts = new List<echosign_dev1__Agreement_Type__c>();
            for (String tn : agreementTypeNames) {
                if (!agreementTypeIdByName.containsKey(tn)) typeInserts.add(new echosign_dev1__Agreement_Type__c(Name = tn));
            }

            if (!typeInserts.isEmpty() && !options.dryRun) {
                Database.SaveResult[] srs = Database.insert(typeInserts, false);
                for (Integer i = 0; i < srs.size(); i++) {
                    if (srs[i].isSuccess()) out.agreementTypesInserted++;
                    else out.warnings.add('Agreement Type insert failed ' + typeInserts[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
                }
            } else {
                out.agreementTypesInserted = typeInserts.size();
            }

            agreementTypeIdByName.clear();
            for (echosign_dev1__Agreement_Type__c t : [
                SELECT Id, Name, CreatedDate
                FROM echosign_dev1__Agreement_Type__c
                WHERE Name IN :agreementTypeNames
                ORDER BY Name ASC, CreatedDate ASC, Id ASC
            ]) {
                if (!agreementTypeIdByName.containsKey(t.Name)) {
                    agreementTypeIdByName.put(t.Name, t.Id);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate Agreement Type already exists for Name "' + t.Name + '". Using the first row.');
                }
            }
        }

        Map<String, List<echosign_dev1__Agreement_Template__c>> templatesByName = new Map<String, List<echosign_dev1__Agreement_Template__c>>();
        if (!agreementNames.isEmpty()) {
            Set<String> templateIdentityKeys = new Set<String>();
            for (echosign_dev1__Agreement_Template__c t : [
                SELECT Id, Name, echosign_dev1__Agreement_Type__c
                FROM echosign_dev1__Agreement_Template__c
                WHERE Name IN :agreementNames
                ORDER BY Name ASC, CreatedDate ASC, Id ASC
            ]) {
                String templateIdentityKey = t.Name + '|' + String.valueOf(t.echosign_dev1__Agreement_Type__c);
                if (templateIdentityKeys.contains(templateIdentityKey)) {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate Agreement Template already exists for Name/Type "' + templateIdentityKey + '". Using the first row.');
                    continue;
                }
                templateIdentityKeys.add(templateIdentityKey);
                if (!templatesByName.containsKey(t.Name)) templatesByName.put(t.Name, new List<echosign_dev1__Agreement_Template__c>());
                templatesByName.get(t.Name).add(t);
            }
        }

        if (options.seedAgreementTypeAndTemplateRecords && !scopedAgreementRows.isEmpty()) {
            List<echosign_dev1__Agreement_Template__c> templateInserts = new List<echosign_dev1__Agreement_Template__c>();
            Set<String> doneKeys = new Set<String>();

            for (List<String> row : scopedAgreementRows) {
                String templateName = row[1];
                String typeName = row[2];
                if (String.isBlank(templateName)) continue;

                String tk = templateName + '|' + typeName;
                if (doneKeys.contains(tk)) continue;
                doneKeys.add(tk);

                Id typeId = String.isBlank(typeName) ? null : agreementTypeIdByName.get(typeName);
                if (!String.isBlank(typeName) && typeId == null) {
                    out.warnings.add('Cannot seed template ' + templateName + ': missing type ' + typeName);
                    continue;
                }

                Boolean alreadyExists = false;
                List<echosign_dev1__Agreement_Template__c> existing = templatesByName.get(templateName);
                if (existing != null) {
                    if (typeId == null) alreadyExists = true;
                    else {
                        for (echosign_dev1__Agreement_Template__c e : existing) {
                            if (e.echosign_dev1__Agreement_Type__c == typeId) {
                                alreadyExists = true;
                                break;
                            }
                        }
                    }
                }

                if (!alreadyExists) {
                    echosign_dev1__Agreement_Template__c nt = new echosign_dev1__Agreement_Template__c(Name = templateName);
                    if (typeId != null) nt.echosign_dev1__Agreement_Type__c = typeId;
                    templateInserts.add(nt);
                }
            }

            if (!templateInserts.isEmpty() && !options.dryRun) {
                Database.SaveResult[] srs = Database.insert(templateInserts, false);
                for (Integer i = 0; i < srs.size(); i++) {
                    if (srs[i].isSuccess()) out.agreementTemplatesInserted++;
                    else out.warnings.add('Agreement Template insert failed ' + templateInserts[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
                }
            } else {
                out.agreementTemplatesInserted = templateInserts.size();
            }

            templatesByName.clear();
            if (!agreementNames.isEmpty()) {
                Set<String> templateIdentityKeys = new Set<String>();
                for (echosign_dev1__Agreement_Template__c t : [
                    SELECT Id, Name, echosign_dev1__Agreement_Type__c
                    FROM echosign_dev1__Agreement_Template__c
                    WHERE Name IN :agreementNames
                    ORDER BY Name ASC, CreatedDate ASC, Id ASC
                ]) {
                    String templateIdentityKey = t.Name + '|' + String.valueOf(t.echosign_dev1__Agreement_Type__c);
                    if (templateIdentityKeys.contains(templateIdentityKey)) {
                        out.duplicateExistingRowsDetected++;
                        out.warnings.add('Duplicate Agreement Template already exists for Name/Type "' + templateIdentityKey + '". Using the first row.');
                        continue;
                    }
                    templateIdentityKeys.add(templateIdentityKey);
                    if (!templatesByName.containsKey(t.Name)) templatesByName.put(t.Name, new List<echosign_dev1__Agreement_Template__c>());
                    templatesByName.get(t.Name).add(t);
                }
            }
        }

        Map<Id, Id> desiredTemplateByProgramId = new Map<Id, Id>();
        Map<Id, String> desiredTemplateSourceByProgramId = new Map<Id, String>();
        for (List<String> row : scopedAgreementRows) {
            String ref = row[0];
            String templateName = row[1];
            String typeName = row[2];

            if (String.isBlank(ref) || String.isBlank(templateName)) {
                out.agreementLinksSkipped++;
                continue;
            }

            List<Id> targetIds = programIdsByRef.get(ref);
            if (targetIds == null || targetIds.isEmpty()) {
                out.agreementLinksSkipped++;
                out.warnings.add('No VC found for agreement ref ' + ref);
                continue;
            }

            List<echosign_dev1__Agreement_Template__c> candidates = templatesByName.get(templateName);
            if (candidates == null || candidates.isEmpty()) {
                out.agreementLinksSkipped++;
                out.warnings.add('Missing template ' + templateName);
                continue;
            }

            Id typeId = String.isBlank(typeName) ? null : agreementTypeIdByName.get(typeName);
            Id chosenId;
            if (typeId == null) {
                chosenId = candidates[0].Id;
            } else {
                for (echosign_dev1__Agreement_Template__c c : candidates) {
                    if (c.echosign_dev1__Agreement_Type__c == typeId) {
                        chosenId = c.Id;
                        break;
                    }
                }
                if (chosenId == null) {
                    out.agreementLinksSkipped++;
                    out.warnings.add('Template/type mismatch ' + templateName + '/' + typeName);
                    continue;
                }
            }

            for (Id pid : targetIds) {
                if (!desiredTemplateByProgramId.containsKey(pid)) {
                    desiredTemplateByProgramId.put(pid, chosenId);
                    desiredTemplateSourceByProgramId.put(pid, templateName + '|' + typeName);
                } else if (desiredTemplateByProgramId.get(pid) != chosenId) {
                    out.duplicateSeedRowsSkipped++;
                    out.warnings.add(
                        'Conflicting agreement mappings for vendor program ' + String.valueOf(pid) +
                        '. Keeping first mapping (' + desiredTemplateSourceByProgramId.get(pid) +
                        ') and skipping (' + templateName + '|' + typeName + ').'
                    );
                }
            }
        }

        List<Vendor_Customization__c> agreementUpdates = new List<Vendor_Customization__c>();
        if (!desiredTemplateByProgramId.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Associated_Agreement_Template__c
                FROM Vendor_Customization__c
                WHERE Id IN :desiredTemplateByProgramId.keySet()
            ]) {
                Id desired = desiredTemplateByProgramId.get(vc.Id);
                if (desired != null && vc.Associated_Agreement_Template__c != desired) {
                    vc.Associated_Agreement_Template__c = desired;
                    agreementUpdates.add(vc);
                }
            }
        }

        if (!agreementUpdates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(agreementUpdates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.agreementLinksUpdated++;
                else out.warnings.add('Agreement link update failed (' + agreementUpdates[i].Id + '): ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.agreementLinksUpdated = agreementUpdates.size();
        }

        if (options.cleanupDuplicates) {
            cleanupAgreementTemplateDuplicates(agreementNames, out, options);
            cleanupAgreementTypeDuplicates(agreementTypeNames, out, options);
        }

        return out;
    }

    public static Result seedVendorProgramRequirements() {
        return seedVendorProgramRequirements(new Options());
    }

    public static Result seedVendorProgramRequirements(Options inputOptions) {
        Options options = normalizeOptions(inputOptions);
        Result out = new Result();

        if (!options.seedVendorProgramRequirements) return out;

        Schema.SObjectType requirementType = Schema.getGlobalDescribe().get('Vendor_Program_Requirement__c');
        if (requirementType == null) {
            out.warnings.add('Vendor_Program_Requirement__c not found in org. Skipping Vendor Program Requirement seed.');
            return out;
        }

        Map<String, Schema.SObjectField> requirementFieldMap = requirementType.getDescribe().fields.getMap();
        if (!requirementFieldMap.containsKey('Vendor_Program__c') || !requirementFieldMap.containsKey('Requirement_Type__c')) {
            out.warnings.add('Vendor Program Requirement object is missing expected fields. Skipping seed.');
            return out;
        }

        List<List<Object>> defaultRequirementRows =
            dedupeVendorProgramRequirementTypeRows(getDefaultVendorProgramRequirementTypeRows(), out);
        List<List<Object>> inputLabelRequirementRows =
            dedupeVendorProgramRequirementTypeRows(getInputVendorProgramRequirementTypeRows(), out);
        if (defaultRequirementRows.isEmpty()) {
            out.warnings.add('No default Vendor Program Requirement rows configured. Skipping seed.');
            return out;
        }

        List<List<Object>> programRows = dedupeProgramRowsByRef(getProgramRows(), out);
        Set<String> selectedVendors = normalizeVendorNames(options.vendorNames);
        Boolean hasFilter = !selectedVendors.isEmpty();

        List<List<Object>> scopedProgramRows = new List<List<Object>>();
        for (List<Object> row : programRows) {
            String vendorName = row.size() > 1 ? (String) row[1] : null;
            if (!hasFilter || selectedVendors.contains(vendorName)) scopedProgramRows.add(row);
        }
        if (scopedProgramRows.isEmpty()) {
            out.warnings.add('No Vendor Program rows matched vendorNames filter for Vendor Program Requirement seed.');
            return out;
        }

        List<List<String>> contractReferenceRows = dedupeContractReferenceRows(getContractReferenceRows(), out);
        Map<String, String> contractDevByName = new Map<String, String>();
        for (List<String> row : contractReferenceRows) contractDevByName.put(row[0], row[1]);

        Set<String> vendorNames = new Set<String>();
        Set<String> neededContractNames = new Set<String>();
        Set<String> neededContractDevs = new Set<String>();
        for (List<Object> row : scopedProgramRows) {
            String vendorName = row.size() > 1 ? (String) row[1] : null;
            String contractName = row.size() > 2 ? (String) row[2] : null;
            if (!String.isBlank(vendorName)) vendorNames.add(vendorName);
            if (!String.isBlank(contractName)) {
                neededContractNames.add(contractName);
                String dev = contractDevByName.get(contractName);
                if (!String.isBlank(dev)) neededContractDevs.add(dev);
            }
        }

        Map<String, Vendor__c> vendorByName = new Map<String, Vendor__c>();
        if (!vendorNames.isEmpty()) {
            for (Vendor__c v : [SELECT Id, Name FROM Vendor__c WHERE Name IN :vendorNames]) {
                vendorByName.put(v.Name, v);
            }
        }

        Map<String, Id> contractByName = new Map<String, Id>();
        Map<String, Id> contractByDev = new Map<String, Id>();
        if (!neededContractNames.isEmpty()) {
            for (Contract_Record_Type_Reference__c ref : [
                SELECT Id, Name, Developer_Name__c
                FROM Contract_Record_Type_Reference__c
                WHERE Name IN :neededContractNames OR Developer_Name__c IN :neededContractDevs
            ]) {
                if (!contractByName.containsKey(ref.Name)) contractByName.put(ref.Name, ref.Id);
                if (!String.isBlank(ref.Developer_Name__c) && !contractByDev.containsKey(ref.Developer_Name__c)) {
                    contractByDev.put(ref.Developer_Name__c, ref.Id);
                }
            }
        }

        Set<Id> vendorIds = new Set<Id>();
        for (Vendor__c v : vendorByName.values()) vendorIds.add(v.Id);

        Map<String, List<Vendor_Customization__c>> programsByExactKey = new Map<String, List<Vendor_Customization__c>>();
        Map<String, List<Vendor_Customization__c>> programsByVendorLabel = new Map<String, List<Vendor_Customization__c>>();
        Map<String, List<Vendor_Customization__c>> programsByCoreKey = new Map<String, List<Vendor_Customization__c>>();
        if (!vendorIds.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Contract_Record_Type__c, Label__c, Retail_Option__c, Business_Vertical__c, CreatedDate
                FROM Vendor_Customization__c
                WHERE Vendor__c IN :vendorIds
                ORDER BY CreatedDate ASC, Id ASC
            ]) {
                String exactKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c)
                    + '|' + String.valueOf(vc.Label__c);
                if (!programsByExactKey.containsKey(exactKey)) {
                    programsByExactKey.put(exactKey, new List<Vendor_Customization__c>());
                }
                programsByExactKey.get(exactKey).add(vc);

                String labelKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Label__c);
                if (!programsByVendorLabel.containsKey(labelKey)) {
                    programsByVendorLabel.put(labelKey, new List<Vendor_Customization__c>());
                }
                programsByVendorLabel.get(labelKey).add(vc);

                String coreKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c);
                if (!programsByCoreKey.containsKey(coreKey)) {
                    programsByCoreKey.put(coreKey, new List<Vendor_Customization__c>());
                }
                programsByCoreKey.get(coreKey).add(vc);
            }
        }

        Map<Id, Vendor_Customization__c> targetProgramById = new Map<Id, Vendor_Customization__c>();
        Map<Id, String> vendorProgramIdToSeedRef = new Map<Id, String>();
        for (List<Object> row : scopedProgramRows) {
            String ref = row.size() > 0 ? (String) row[0] : null;
            String vendorName = row.size() > 1 ? (String) row[1] : null;
            String contractName = row.size() > 2 ? (String) row[2] : null;
            String label = row.size() > 3 ? (String) row[3] : null;
            String retail = row.size() > 4 ? (String) row[4] : null;
            String business = row.size() > 5 ? (String) row[5] : null;
            Integer copies = row.size() > 10 ? (Integer) row[10] : 1;
            if (copies == null || copies < 1) copies = 1;

            Vendor__c v = vendorByName.get(vendorName);
            if (v == null) {
                out.warnings.add('Vendor missing for Vendor Program Requirement ref ' + ref + ': ' + vendorName);
                continue;
            }

            Id contractId;
            if (!String.isBlank(contractName)) {
                contractId = contractByName.get(contractName);
                if (contractId == null) contractId = contractByDev.get(contractName);
                if (contractId == null && contractDevByName.containsKey(contractName)) {
                    contractId = contractByDev.get(contractDevByName.get(contractName));
                }
            }

            String exactKey = String.valueOf(v.Id) + '|' + String.valueOf(contractId)
                + '|' + String.valueOf(retail) + '|' + String.valueOf(business)
                + '|' + String.valueOf(label);
            List<Vendor_Customization__c> matches = programsByExactKey.get(exactKey);
            if (matches == null || matches.isEmpty()) {
                String labelKey = String.valueOf(v.Id) + '|' + String.valueOf(label);
                matches = programsByVendorLabel.get(labelKey);
            }
            if (matches == null || matches.isEmpty()) {
                String coreKey = String.valueOf(v.Id) + '|' + String.valueOf(contractId)
                    + '|' + String.valueOf(retail) + '|' + String.valueOf(business);
                matches = programsByCoreKey.get(coreKey);
            }
            if (matches == null || matches.isEmpty()) {
                out.warnings.add('Vendor program not found for Vendor Program Requirement ref ' + ref);
                continue;
            }

            Integer maxCopies = Math.min(copies, matches.size());
            if (matches.size() < copies) {
                out.warnings.add(
                    'Vendor Program Requirement seed for ref ' + ref +
                    ' requested ' + copies + ' copies but only found ' + matches.size() + '.'
                );
            }
            for (Integer i = 0; i < maxCopies; i++) {
                targetProgramById.put(matches[i].Id, matches[i]);
                vendorProgramIdToSeedRef.put(matches[i].Id, ref);
            }
        }

        if (targetProgramById.isEmpty()) {
            out.warnings.add('No Vendor Program rows resolved for Vendor Program Requirement seed.');
            return out;
        }

        Set<String> validRequirementTypes = new Set<String>();
        for (Schema.PicklistEntry e : requirementFieldMap.get('Requirement_Type__c').getDescribe().getPicklistValues()) {
            if (e.isActive()) validRequirementTypes.add(e.getValue());
        }

        Map<String, List<List<Object>>> requirementRowsByProgramRef = getVendorProgramRequirementRowsByProgramRef();

        Set<Id> targetProgramIds = targetProgramById.keySet();
        List<SObject> existingRows = Database.query(
            'SELECT Id, Vendor_Program__c, Requirement_Type__c, Sequence__c, Is_Required__c, Active__c, CreatedDate ' +
            'FROM Vendor_Program_Requirement__c ' +
            'WHERE Vendor_Program__c IN :targetProgramIds ' +
            'ORDER BY Vendor_Program__c ASC, Requirement_Type__c ASC, CreatedDate ASC, Id ASC'
        );

        Map<String, SObject> existingByKey = new Map<String, SObject>();
        List<SObject> duplicateExistingRows = new List<SObject>();
        for (SObject row : existingRows) {
            String key = String.valueOf(row.get('Vendor_Program__c')) + '|' + normalizeKeyPart(row.get('Requirement_Type__c'));
            if (!existingByKey.containsKey(key)) {
                existingByKey.put(key, row);
            } else {
                duplicateExistingRows.add(row);
                out.duplicateExistingRowsDetected++;
            }
        }

        List<SObject> inserts = new List<SObject>();
        List<SObject> updates = new List<SObject>();
        Set<String> processedSeedKeys = new Set<String>();

        for (Id programId : targetProgramById.keySet()) {
            Vendor_Customization__c vc = targetProgramById.get(programId);
            String seedProgramRef = vendorProgramIdToSeedRef.get(programId);

            List<List<Object>> requirementRowsForProgram;
            if (
                seedProgramRef != null &&
                requirementRowsByProgramRef != null &&
                requirementRowsByProgramRef.containsKey(seedProgramRef)
            ) {
                requirementRowsForProgram = dedupeVendorProgramRequirementTypeRows(
                    requirementRowsByProgramRef.get(seedProgramRef),
                    out
                );
            } else if (normalizeKeyPart(vc.Label__c) == 'input') {
                requirementRowsForProgram = inputLabelRequirementRows;
            } else {
                requirementRowsForProgram = defaultRequirementRows;
            }

            Boolean useInputLabelRows = normalizeKeyPart(vc.Label__c) == 'input';
            if (useInputLabelRows && requirementRowsForProgram.isEmpty()) {
                out.warnings.add(
                    'Vendor Program label is "input" for program ' + programId +
                    '; no custom requirement rows configured, so default set was skipped.'
                );
                continue;
            }

            for (List<Object> reqRow : requirementRowsForProgram) {
                String requirementTypeName = reqRow.size() > 0 ? (String) reqRow[0] : null;
                Integer sequence = reqRow.size() > 1 ? (Integer) reqRow[1] : 1;
                Boolean isRequired = reqRow.size() > 2 ? (Boolean) reqRow[2] : true;
                Boolean active = reqRow.size() > 3 ? (Boolean) reqRow[3] : true;

                if (String.isBlank(requirementTypeName)) {
                    out.duplicateSeedRowsSkipped++;
                    out.warnings.add('Skip Vendor Program Requirement row with blank Requirement Type.');
                    continue;
                }

                if (!validRequirementTypes.contains(requirementTypeName)) {
                    out.duplicateSeedRowsSkipped++;
                    out.warnings.add(
                        'Skip Vendor Program Requirement row, invalid Requirement Type "' +
                        requirementTypeName + '".'
                    );
                    continue;
                }

                String key = String.valueOf(programId) + '|' + normalizeKeyPart(requirementTypeName);
                if (processedSeedKeys.contains(key)) {
                    out.duplicateSeedRowsSkipped++;
                    continue;
                }
                processedSeedKeys.add(key);

                SObject existing = existingByKey.get(key);
                if (existing == null) {
                    SObject nr = requirementType.newSObject();
                    nr.put('Vendor_Program__c', programId);
                    nr.put('Requirement_Type__c', requirementTypeName);
                    nr.put('Sequence__c', sequence);
                    nr.put('Is_Required__c', isRequired);
                    nr.put('Active__c', active);
                    inserts.add(nr);
                } else {
                    Boolean changed = false;
                    Decimal existingSequenceDecimal = (Decimal) existing.get('Sequence__c');
                    Integer existingSequence = existingSequenceDecimal == null ? null : existingSequenceDecimal.intValue();
                    if (existingSequence != sequence) { existing.put('Sequence__c', sequence); changed = true; }
                    if ((Boolean) existing.get('Is_Required__c') != isRequired) { existing.put('Is_Required__c', isRequired); changed = true; }
                    if ((Boolean) existing.get('Active__c') != active) { existing.put('Active__c', active); changed = true; }
                    if (changed) updates.add(existing);
                }
            }
        }

        if (!inserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(inserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.vendorProgramRequirementsInserted++;
                else out.warnings.add('Vendor Program Requirement insert failed: ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.vendorProgramRequirementsInserted = inserts.size();
        }

        if (!updates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(updates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.vendorProgramRequirementsUpdated++;
                else out.warnings.add('Vendor Program Requirement update failed: ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.vendorProgramRequirementsUpdated = updates.size();
        }

        if (options.cleanupDuplicates && !duplicateExistingRows.isEmpty()) {
            applyCleanupDeletes(duplicateExistingRows, 'Vendor Program Requirement', out, options);
        }

        return out;
    }

    public static Result seedCredentialData() {
        return seedCredentialData(new Options());
    }

    public static Result seedCredentialData(Options inputOptions) {
        Options options = normalizeOptions(inputOptions);
        Result out = new Result();

        List<List<String>> contractReferenceRows = dedupeContractReferenceRows(getContractReferenceRows(), out);
        List<List<String>> programLocatorRows = dedupeCredentialProgramLocatorRowsByRef(getCredentialProgramLocatorRows(), out);
        List<List<Object>> credentialTypeRows = dedupeCredentialTypeRows(getCredentialTypeRows(), out);
        List<List<Object>> requiredRows = dedupeRequiredCredentialRows(getRequiredCredentialRows(), out);
        List<List<String>> dependencyRows = dedupeDependencyRows(getDependencyRows(), out);

        Set<String> selectedVendors = normalizeVendorNames(options.vendorNames);
        Boolean hasFilter = !selectedVendors.isEmpty();

        List<List<String>> scopedLocatorRows = new List<List<String>>();
        Set<String> scopedRefs = new Set<String>();
        for (List<String> row : programLocatorRows) {
            String ref = row[0];
            String vendorName = row[1];
            if (!hasFilter || selectedVendors.contains(vendorName)) {
                scopedLocatorRows.add(row);
                scopedRefs.add(ref);
            }
        }

        List<List<Object>> scopedCredentialRows = new List<List<Object>>();
        for (List<Object> row : credentialTypeRows) {
            if (scopedRefs.contains((String) row[0])) scopedCredentialRows.add(row);
        }

        List<List<Object>> scopedRequiredRows = new List<List<Object>>();
        for (List<Object> row : requiredRows) {
            if (scopedRefs.contains((String) row[0])) scopedRequiredRows.add(row);
        }

        List<List<String>> scopedDependencyRows = new List<List<String>>();
        for (List<String> row : dependencyRows) {
            if (scopedRefs.contains(row[0])) scopedDependencyRows.add(row);
        }

        if (scopedLocatorRows.isEmpty()) {
            out.warnings.add('No credential rows matched vendorNames filter.');
        }

        Set<String> vendorNames = new Set<String>();
        for (List<String> row : scopedLocatorRows) vendorNames.add(row[1]);

        Map<String, Vendor__c> vendorByName = new Map<String, Vendor__c>();
        if (!vendorNames.isEmpty()) {
            for (Vendor__c v : [SELECT Id, Name FROM Vendor__c WHERE Name IN :vendorNames]) {
                vendorByName.put(v.Name, v);
            }
        }

        Map<String, String> contractDevByName = new Map<String, String>();
        for (List<String> row : contractReferenceRows) contractDevByName.put(row[0], row[1]);

        Set<String> neededContractNames = new Set<String>();
        Set<String> neededContractDevs = new Set<String>();
        for (List<String> row : scopedLocatorRows) {
            String cn = row[2];
            if (String.isBlank(cn)) continue;
            neededContractNames.add(cn);
            String dev = contractDevByName.get(cn);
            if (!String.isBlank(dev)) neededContractDevs.add(dev);
        }

        Map<String, Id> contractByName = new Map<String, Id>();
        Map<String, Id> contractByDev = new Map<String, Id>();
        if (!neededContractNames.isEmpty()) {
            for (Contract_Record_Type_Reference__c ref : [
                SELECT Id, Name, Developer_Name__c
                FROM Contract_Record_Type_Reference__c
                WHERE Name IN :neededContractNames OR Developer_Name__c IN :neededContractDevs
            ]) {
                if (!contractByName.containsKey(ref.Name)) contractByName.put(ref.Name, ref.Id);
                if (!String.isBlank(ref.Developer_Name__c) && !contractByDev.containsKey(ref.Developer_Name__c)) contractByDev.put(ref.Developer_Name__c, ref.Id);
            }
        }

        Set<Id> vendorIds = new Set<Id>();
        for (Vendor__c v : vendorByName.values()) vendorIds.add(v.Id);

        Map<String, List<Vendor_Customization__c>> programsByExactKey = new Map<String, List<Vendor_Customization__c>>();
        Map<String, List<Vendor_Customization__c>> programsByVendorLabel = new Map<String, List<Vendor_Customization__c>>();
        Map<String, List<Vendor_Customization__c>> programsByCoreKey = new Map<String, List<Vendor_Customization__c>>();
        if (!vendorIds.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Vendor__r.Name, Contract_Record_Type__c, Label__c, Retail_Option__c, Business_Vertical__c
                FROM Vendor_Customization__c
                WHERE Vendor__c IN :vendorIds
            ]) {
                String exactKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c)
                    + '|' + String.valueOf(vc.Label__c);
                if (!programsByExactKey.containsKey(exactKey)) programsByExactKey.put(exactKey, new List<Vendor_Customization__c>());
                programsByExactKey.get(exactKey).add(vc);

                String labelKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Label__c);
                if (!programsByVendorLabel.containsKey(labelKey)) programsByVendorLabel.put(labelKey, new List<Vendor_Customization__c>());
                programsByVendorLabel.get(labelKey).add(vc);
            }
        }

        Map<String, List<Id>> programIdsByRef = new Map<String, List<Id>>();
        Set<Id> targetProgramIds = new Set<Id>();
        for (List<String> row : scopedLocatorRows) {
            String ref = row[0];
            String vendorName = row[1];
            String contractName = row[2];
            String label = row[3];
            String retail = row[4];
            String business = row[5];

            Vendor__c v = vendorByName.get(vendorName);
            if (v == null) {
                out.warnings.add('Vendor missing for ref ' + ref + ': ' + vendorName);
                continue;
            }

            Id contractId;
            if (!String.isBlank(contractName)) {
                contractId = contractByName.get(contractName);
                if (contractId == null) contractId = contractByDev.get(contractName);
                if (contractId == null && contractDevByName.containsKey(contractName)) {
                    contractId = contractByDev.get(contractDevByName.get(contractName));
                }
            }

            String exactKey = String.valueOf(v.Id) + '|' + String.valueOf(contractId)
                + '|' + String.valueOf(retail) + '|' + String.valueOf(business)
                + '|' + String.valueOf(label);

            List<Vendor_Customization__c> matches = programsByExactKey.get(exactKey);
            if (matches == null || matches.isEmpty()) {
                String labelKey = String.valueOf(v.Id) + '|' + String.valueOf(label);
                matches = programsByVendorLabel.get(labelKey);
            }

            if (matches == null || matches.isEmpty()) {
                out.warnings.add('Vendor program not found for ref ' + ref + ' (' + vendorName + ' / ' + label + ')');
                continue;
            }

            // Credential data should attach to one canonical program row per ref.
            // If duplicates exist in an org, use the first match deterministically.
            if (matches.size() > 1) {
                out.warnings.add('Multiple vendor programs matched ref ' + ref + '; using the first match only.');
            }
            Id chosenProgramId = matches[0].Id;
            if (programIdsByRef.containsKey(ref)) {
                Id existingProgramId = programIdsByRef.get(ref)[0];
                if (existingProgramId != chosenProgramId) {
                    out.duplicateSeedRowsSkipped++;
                    out.warnings.add('Duplicate credential program locator for ref ' + ref + ' points to multiple programs. Keeping first match only.');
                }
                continue;
            }
            programIdsByRef.put(ref, new List<Id>{ chosenProgramId });
            targetProgramIds.add(chosenProgramId);
        }

        Map<Id, Vendor_Customization__c> programById = new Map<Id, Vendor_Customization__c>();
        if (!targetProgramIds.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Vendor__r.Name, Label__c
                FROM Vendor_Customization__c
                WHERE Id IN :targetProgramIds
            ]) {
                programById.put(vc.Id, vc);
            }
        }

        Boolean credentialTypeHasVendorField =
            Schema.SObjectType.External_Contact_Credential_Type__c.fields.getMap().containsKey('Vendor__c');
        Map<String, External_Contact_Credential_Type__c> existingTypeByKey = new Map<String, External_Contact_Credential_Type__c>();
        if (!targetProgramIds.isEmpty()) {
            for (External_Contact_Credential_Type__c t : [
                SELECT Id, Name, Vendor_Customization__c, Active__c, Sort_Order__c, Unique_Key__c
                FROM External_Contact_Credential_Type__c
                WHERE Vendor_Customization__c IN :targetProgramIds
            ]) {
                String key = String.valueOf(t.Vendor_Customization__c) + '|' + t.Name;
                if (!existingTypeByKey.containsKey(key)) {
                    existingTypeByKey.put(key, t);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate existing credential type found for key ' + key + '. Keeping first row.');
                }
            }
        }

        List<External_Contact_Credential_Type__c> typeInserts = new List<External_Contact_Credential_Type__c>();
        List<External_Contact_Credential_Type__c> typeUpdates = new List<External_Contact_Credential_Type__c>();
        Set<String> processedTypeKeys = new Set<String>();

        for (List<Object> row : scopedCredentialRows) {
            String ref = (String) row[0];
            String typeName = (String) row[1];
            Integer sortOrder = (Integer) row[2];
            Boolean active = (Boolean) row[3];

            List<Id> ids = programIdsByRef.get(ref);
            if (ids == null || ids.isEmpty()) {
                out.warnings.add('Skip credential row, no program IDs for ref ' + ref);
                continue;
            }

            for (Id pid : ids) {
                String key = String.valueOf(pid) + '|' + typeName;
                if (processedTypeKeys.contains(key)) {
                    out.duplicateSeedRowsSkipped++;
                    continue;
                }
                processedTypeKeys.add(key);

                Vendor_Customization__c vc = programById.get(pid);
                if (vc == null) {
                    out.warnings.add('Skip credential row, program missing for id ' + pid);
                    continue;
                }
                if (credentialTypeHasVendorField && vc.Vendor__c == null) {
                    out.warnings.add(
                        'Skip credential row, program ' + pid +
                        ' has no Vendor__c (required for External Contact Credential Type): ' + typeName
                    );
                    continue;
                }

                String uniqueKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(pid) + '|' + typeName;
                External_Contact_Credential_Type__c existing = existingTypeByKey.get(key);
                if (existing == null) {
                    External_Contact_Credential_Type__c newType = new External_Contact_Credential_Type__c(
                        Name = typeName,
                        Vendor_Customization__c = pid,
                        Active__c = active,
                        Sort_Order__c = sortOrder,
                        Unique_Key__c = uniqueKey
                    );
                    if (credentialTypeHasVendorField) newType.put('Vendor__c', vc.Vendor__c);
                    typeInserts.add(newType);
                } else {
                    Boolean changed = false;
                    if (credentialTypeHasVendorField) {
                        existing.put('Vendor__c', vc.Vendor__c);
                        changed = true;
                    }
                    if (existing.Vendor_Customization__c != pid) { existing.Vendor_Customization__c = pid; changed = true; }
                    if (existing.Active__c != active) { existing.Active__c = active; changed = true; }
                    Integer existingOrder = existing.Sort_Order__c == null ? null : existing.Sort_Order__c.intValue();
                    if (existingOrder != sortOrder) { existing.Sort_Order__c = sortOrder; changed = true; }
                    if (existing.Unique_Key__c != uniqueKey) { existing.Unique_Key__c = uniqueKey; changed = true; }
                    if (changed) typeUpdates.add(existing);
                }
            }
        }

        if (!typeInserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(typeInserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.credentialTypesInserted++;
                else out.warnings.add('Credential type insert failed ' + typeInserts[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.credentialTypesInserted = typeInserts.size();
        }

        if (!typeUpdates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(typeUpdates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.credentialTypesUpdated++;
                else out.warnings.add('Credential type update failed ' + typeUpdates[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.credentialTypesUpdated = typeUpdates.size();
        }

        Set<String> scopedTypeNames = new Set<String>();
        for (List<Object> row : scopedCredentialRows) scopedTypeNames.add((String) row[1]);

        Map<String, Id> typeIdByProgramAndName = new Map<String, Id>();
        if (!targetProgramIds.isEmpty() && !scopedTypeNames.isEmpty()) {
            for (External_Contact_Credential_Type__c t : [
                SELECT Id, Name, Vendor_Customization__c
                FROM External_Contact_Credential_Type__c
                WHERE Vendor_Customization__c IN :targetProgramIds
                AND Name IN :scopedTypeNames
            ]) {
                String key = String.valueOf(t.Vendor_Customization__c) + '|' + t.Name;
                if (!typeIdByProgramAndName.containsKey(key)) {
                    typeIdByProgramAndName.put(key, t.Id);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate existing credential type found while resolving type IDs for key ' + key + '. Keeping first row.');
                }
            }
        }

        Map<String, Required_Credential__c> existingReqByKey = new Map<String, Required_Credential__c>();
        if (!targetProgramIds.isEmpty()) {
            for (Required_Credential__c rc : [
                SELECT Id, Vendor_Customization__c, External_Contact_Credential_Type__c, Is_Required__c, Sequence__c
                FROM Required_Credential__c
                WHERE Vendor_Customization__c IN :targetProgramIds
            ]) {
                String key = String.valueOf(rc.Vendor_Customization__c) + '|' + String.valueOf(rc.External_Contact_Credential_Type__c);
                if (!existingReqByKey.containsKey(key)) {
                    existingReqByKey.put(key, rc);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate existing required credential found for key ' + key + '. Keeping first row.');
                }
            }
        }

        List<Required_Credential__c> reqInserts = new List<Required_Credential__c>();
        List<Required_Credential__c> reqUpdates = new List<Required_Credential__c>();
        Set<String> processedReqKeys = new Set<String>();

        for (List<Object> row : scopedRequiredRows) {
            String ref = (String) row[0];
            String typeName = (String) row[1];
            Boolean isRequired = (Boolean) row[2];
            Integer sequence = (Integer) row[3];

            List<Id> ids = programIdsByRef.get(ref);
            if (ids == null || ids.isEmpty()) {
                out.warnings.add('Skip required row, no program IDs for ref ' + ref);
                continue;
            }

            for (Id pid : ids) {
                Id typeId = typeIdByProgramAndName.get(String.valueOf(pid) + '|' + typeName);
                if (typeId == null) {
                    out.warnings.add('Skip required row, missing type ' + typeName + ' for ref ' + ref);
                    continue;
                }

                String key = String.valueOf(pid) + '|' + String.valueOf(typeId);
                if (processedReqKeys.contains(key)) {
                    out.duplicateSeedRowsSkipped++;
                    continue;
                }
                processedReqKeys.add(key);

                Required_Credential__c existing = existingReqByKey.get(key);
                if (existing == null) {
                    reqInserts.add(new Required_Credential__c(
                        Vendor_Customization__c = pid,
                        External_Contact_Credential_Type__c = typeId,
                        Is_Required__c = isRequired,
                        Sequence__c = sequence
                    ));
                } else {
                    Boolean changed = false;
                    if (existing.Is_Required__c != isRequired) { existing.Is_Required__c = isRequired; changed = true; }
                    Integer existingSeq = existing.Sequence__c == null ? null : existing.Sequence__c.intValue();
                    if (existingSeq != sequence) { existing.Sequence__c = sequence; changed = true; }
                    if (changed) reqUpdates.add(existing);
                }
            }
        }

        if (!reqInserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(reqInserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.requiredCredentialsInserted++;
                else out.warnings.add('Required credential insert failed: ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.requiredCredentialsInserted = reqInserts.size();
        }

        if (!reqUpdates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(reqUpdates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.requiredCredentialsUpdated++;
                else out.warnings.add('Required credential update failed: ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.requiredCredentialsUpdated = reqUpdates.size();
        }

        Set<String> existingDepKeys = new Set<String>();
        Set<String> existingDepSeenKeys = new Set<String>();
        if (!targetProgramIds.isEmpty()) {
            for (External_Credential_Type_Dependency__c d : [
                SELECT Id, Vendor_Program__c, Credential_Type__c, Depends_On__c
                FROM External_Credential_Type_Dependency__c
                WHERE Vendor_Program__c IN :targetProgramIds
            ]) {
                String key = String.valueOf(d.Vendor_Program__c) + '|' + String.valueOf(d.Credential_Type__c) + '|' + String.valueOf(d.Depends_On__c);
                if (existingDepSeenKeys.contains(key)) {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate existing dependency found for key ' + key + '.');
                }
                existingDepSeenKeys.add(key);
                existingDepKeys.add(key);
            }
        }

        List<External_Credential_Type_Dependency__c> depInserts = new List<External_Credential_Type_Dependency__c>();
        Set<String> processedDepKeys = new Set<String>();

        for (List<String> row : scopedDependencyRows) {
            String ref = row[0];
            String typeName = row[1];
            String dependsOn = row[2];

            List<Id> ids = programIdsByRef.get(ref);
            if (ids == null || ids.isEmpty()) {
                out.warnings.add('Skip dependency row, no program IDs for ref ' + ref);
                continue;
            }

            for (Id pid : ids) {
                Id typeId = typeIdByProgramAndName.get(String.valueOf(pid) + '|' + typeName);
                Id dependsOnId = typeIdByProgramAndName.get(String.valueOf(pid) + '|' + dependsOn);
                if (typeId == null || dependsOnId == null) {
                    out.warnings.add('Skip dependency row, missing type(s) for ' + ref + ': ' + typeName + ' -> ' + dependsOn);
                    continue;
                }

                String key = String.valueOf(pid) + '|' + String.valueOf(typeId) + '|' + String.valueOf(dependsOnId);
                if (existingDepKeys.contains(key)) continue;
                if (processedDepKeys.contains(key)) {
                    out.duplicateSeedRowsSkipped++;
                    continue;
                }
                processedDepKeys.add(key);

                depInserts.add(new External_Credential_Type_Dependency__c(
                    Vendor_Program__c = pid,
                    Credential_Type__c = typeId,
                    Depends_On__c = dependsOnId
                ));
            }
        }

        if (!depInserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(depInserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.dependencyRowsInserted++;
                else out.warnings.add('Dependency insert failed: ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.dependencyRowsInserted = depInserts.size();
        }

        if (options.cleanupDuplicates) {
            cleanupCredentialDuplicates(targetProgramIds, out, options);
        }

        return out;
    }

    public static Result seedTrainingSystems() {
        return seedTrainingSystems(new Options());
    }

    public static Result seedTrainingSystems(Options inputOptions) {
        Options options = normalizeOptions(inputOptions);
        Result out = new Result();

        if (!options.seedTrainingSystems) return out;

        List<List<Object>> trainingSystemRows = dedupeTrainingSystemRowsByName(getTrainingSystemRows(), out);
        if (trainingSystemRows.isEmpty()) return out;

        Set<String> validSystemTypes = new Set<String>();
        String defaultSystemType;
        for (Schema.PicklistEntry e : Training_System__c.System_Type__c.getDescribe().getPicklistValues()) {
            if (!e.isActive()) continue;
            validSystemTypes.add(e.getValue());
            if (defaultSystemType == null) defaultSystemType = e.getValue();
        }
        if (String.isBlank(defaultSystemType)) defaultSystemType = 'Internal';

        Set<String> trainingSystemNames = new Set<String>();
        for (List<Object> row : trainingSystemRows) {
            String tsName = (String) row[0];
            if (!String.isBlank(tsName)) trainingSystemNames.add(tsName.trim());
        }
        if (trainingSystemNames.isEmpty()) return out;

        Map<String, Training_System__c> canonicalByNameKey = new Map<String, Training_System__c>();
        Map<Id, Id> duplicateToCanonical = new Map<Id, Id>();
        for (Training_System__c ts : [
            SELECT Id, Name, Active__c, System_Type__c, CreatedDate
            FROM Training_System__c
            WHERE Name IN :trainingSystemNames
            ORDER BY Name ASC, CreatedDate ASC, Id ASC
        ]) {
            String key = normalizeKeyPart(ts.Name);
            if (!canonicalByNameKey.containsKey(key)) {
                canonicalByNameKey.put(key, ts);
            } else {
                duplicateToCanonical.put(ts.Id, canonicalByNameKey.get(key).Id);
                out.duplicateExistingRowsDetected++;
                out.warnings.add(
                    'Duplicate Training System found for Name "' + ts.Name +
                    '". Using the earliest record as canonical.'
                );
            }
        }

        List<Training_System__c> inserts = new List<Training_System__c>();
        List<Training_System__c> updates = new List<Training_System__c>();

        for (List<Object> row : trainingSystemRows) {
            String tsNameRaw = (String) row[0];
            Boolean active = (Boolean) row[1];
            String systemType = (String) row[2];
            if (String.isBlank(tsNameRaw)) continue;

            String tsName = tsNameRaw.trim();
            if (active == null) active = true;
            if (String.isBlank(systemType) || !validSystemTypes.contains(systemType)) {
                if (!String.isBlank(systemType) && options.strictPicklists) {
                    out.duplicateSeedRowsSkipped++;
                    out.warnings.add(
                        'Skip Training System row for "' + tsName +
                        '" due to invalid System Type "' + systemType + '".'
                    );
                    continue;
                }
                systemType = defaultSystemType;
            }

            String key = normalizeKeyPart(tsName);
            Training_System__c existing = canonicalByNameKey.get(key);
            if (existing == null) {
                inserts.add(new Training_System__c(
                    Name = tsName,
                    Active__c = active,
                    System_Type__c = systemType
                ));
            } else {
                Boolean changed = false;
                if (existing.Active__c != active) {
                    existing.Active__c = active;
                    changed = true;
                }
                if (existing.System_Type__c != systemType) {
                    existing.System_Type__c = systemType;
                    changed = true;
                }
                if (changed) updates.add(existing);
            }
        }

        if (!inserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(inserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.trainingSystemsInserted++;
                else out.warnings.add('Training System insert failed ' + inserts[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.trainingSystemsInserted = inserts.size();
        }

        if (!updates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(updates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.trainingSystemsUpdated++;
                else out.warnings.add('Training System update failed ' + updates[i].Name + ': ' + srs[i].getErrors()[0].getMessage());
            }
        } else {
            out.trainingSystemsUpdated = updates.size();
        }

        if (options.cleanupDuplicates && !duplicateToCanonical.isEmpty()) {
            cleanupTrainingSystemDuplicates(duplicateToCanonical, out, options);
        }

        return out;
    }

    public static Result seedTrainingRequirements() {
        return seedTrainingRequirements(new Options());
    }

    public static Result seedTrainingRequirements(Options inputOptions) {
        Options options = normalizeOptions(inputOptions);
        Result out = new Result();

        if (!options.seedTrainingRequirements) return out;

        List<List<Object>> trainingRequirementRows =
            dedupeTrainingRequirementRows(getTrainingRequirementRows(), out);
        if (trainingRequirementRows.isEmpty()) return out;

        Map<String, List<Object>> programSeedRowByRef = new Map<String, List<Object>>();
        List<List<Object>> programRows = dedupeProgramRowsByRef(getProgramRows(), out);
        for (List<Object> row : programRows) {
            String ref = row.size() > 0 ? (String) row[0] : null;
            if (!String.isBlank(ref)) programSeedRowByRef.put(ref, row);
        }

        Set<String> selectedVendors = normalizeVendorNames(options.vendorNames);
        Boolean hasFilter = !selectedVendors.isEmpty();

        List<List<Object>> scopedRows = new List<List<Object>>();
        Set<String> scopedRefs = new Set<String>();
        for (List<Object> row : trainingRequirementRows) {
            String programRef = row.size() > 0 ? (String) row[0] : null;
            List<Object> programSeed = programSeedRowByRef.get(programRef);
            if (programSeed == null) {
                out.warnings.add('Skip Training Requirement row, unknown programRef: ' + programRef);
                continue;
            }

            String vendorName = programSeed.size() > 1 ? (String) programSeed[1] : null;
            if (!hasFilter || selectedVendors.contains(vendorName)) {
                scopedRows.add(row);
                scopedRefs.add(programRef);
            }
        }

        if (scopedRows.isEmpty()) {
            out.warnings.add('No Training Requirement rows matched vendorNames filter.');
            return out;
        }

        List<List<String>> contractReferenceRows = dedupeContractReferenceRows(getContractReferenceRows(), out);
        Map<String, String> contractDevByName = new Map<String, String>();
        for (List<String> row : contractReferenceRows) contractDevByName.put(row[0], row[1]);

        Set<String> vendorNames = new Set<String>();
        Set<String> neededContractNames = new Set<String>();
        Set<String> neededContractDevs = new Set<String>();
        for (String ref : scopedRefs) {
            List<Object> programSeed = programSeedRowByRef.get(ref);
            if (programSeed == null) continue;

            String vendorName = (String) programSeed[1];
            String contractName = (String) programSeed[2];
            vendorNames.add(vendorName);
            if (!String.isBlank(contractName)) {
                neededContractNames.add(contractName);
                String dev = contractDevByName.get(contractName);
                if (!String.isBlank(dev)) neededContractDevs.add(dev);
            }
        }

        Map<String, Vendor__c> vendorByName = new Map<String, Vendor__c>();
        if (!vendorNames.isEmpty()) {
            for (Vendor__c v : [SELECT Id, Name FROM Vendor__c WHERE Name IN :vendorNames]) {
                vendorByName.put(v.Name, v);
            }
        }

        Map<String, Id> contractByName = new Map<String, Id>();
        Map<String, Id> contractByDev = new Map<String, Id>();
        if (!neededContractNames.isEmpty()) {
            for (Contract_Record_Type_Reference__c ref : [
                SELECT Id, Name, Developer_Name__c
                FROM Contract_Record_Type_Reference__c
                WHERE Name IN :neededContractNames OR Developer_Name__c IN :neededContractDevs
            ]) {
                if (!contractByName.containsKey(ref.Name)) contractByName.put(ref.Name, ref.Id);
                if (!String.isBlank(ref.Developer_Name__c) && !contractByDev.containsKey(ref.Developer_Name__c)) {
                    contractByDev.put(ref.Developer_Name__c, ref.Id);
                }
            }
        }

        Set<Id> vendorIds = new Set<Id>();
        for (Vendor__c v : vendorByName.values()) vendorIds.add(v.Id);

        Map<String, List<Vendor_Customization__c>> programsByExactKey = new Map<String, List<Vendor_Customization__c>>();
        Map<String, List<Vendor_Customization__c>> programsByVendorLabel = new Map<String, List<Vendor_Customization__c>>();
        Map<String, List<Vendor_Customization__c>> programsByCoreKey = new Map<String, List<Vendor_Customization__c>>();
        if (!vendorIds.isEmpty()) {
            for (Vendor_Customization__c vc : [
                SELECT Id, Vendor__c, Contract_Record_Type__c, Label__c, Retail_Option__c, Business_Vertical__c, CreatedDate
                FROM Vendor_Customization__c
                WHERE Vendor__c IN :vendorIds
                ORDER BY CreatedDate ASC, Id ASC
            ]) {
                String exactKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c)
                    + '|' + String.valueOf(vc.Label__c);
                if (!programsByExactKey.containsKey(exactKey)) {
                    programsByExactKey.put(exactKey, new List<Vendor_Customization__c>());
                }
                programsByExactKey.get(exactKey).add(vc);

                String coreKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Contract_Record_Type__c)
                    + '|' + String.valueOf(vc.Retail_Option__c) + '|' + String.valueOf(vc.Business_Vertical__c);
                if (!programsByCoreKey.containsKey(coreKey)) {
                    programsByCoreKey.put(coreKey, new List<Vendor_Customization__c>());
                }
                programsByCoreKey.get(coreKey).add(vc);

                String labelKey = String.valueOf(vc.Vendor__c) + '|' + String.valueOf(vc.Label__c);
                if (!programsByVendorLabel.containsKey(labelKey)) {
                    programsByVendorLabel.put(labelKey, new List<Vendor_Customization__c>());
                }
                programsByVendorLabel.get(labelKey).add(vc);
            }
        }

        Map<String, List<Id>> programIdsByRef = new Map<String, List<Id>>();
        Set<Id> targetProgramIds = new Set<Id>();
        for (String ref : scopedRefs) {
            List<Object> programSeed = programSeedRowByRef.get(ref);
            if (programSeed == null) continue;

            String vendorName = (String) programSeed[1];
            String contractName = (String) programSeed[2];
            String label = (String) programSeed[3];
            String retail = (String) programSeed[4];
            String business = (String) programSeed[5];

            Vendor__c v = vendorByName.get(vendorName);
            if (v == null) {
                out.warnings.add('Vendor missing for Training Requirement ref ' + ref + ': ' + vendorName);
                continue;
            }

            Id contractId;
            if (!String.isBlank(contractName)) {
                contractId = contractByName.get(contractName);
                if (contractId == null) contractId = contractByDev.get(contractName);
                if (contractId == null && contractDevByName.containsKey(contractName)) {
                    contractId = contractByDev.get(contractDevByName.get(contractName));
                }
            }

            String exactKey = String.valueOf(v.Id) + '|' + String.valueOf(contractId)
                + '|' + String.valueOf(retail) + '|' + String.valueOf(business)
                + '|' + String.valueOf(label);

            List<Vendor_Customization__c> matches = programsByExactKey.get(exactKey);
            if (matches == null || matches.isEmpty()) {
                String labelKey = String.valueOf(v.Id) + '|' + String.valueOf(label);
                matches = programsByVendorLabel.get(labelKey);
            }
            if (matches == null || matches.isEmpty()) {
                String coreKey = String.valueOf(v.Id) + '|' + String.valueOf(contractId)
                    + '|' + String.valueOf(retail) + '|' + String.valueOf(business);
                matches = programsByCoreKey.get(coreKey);
            }
            if (matches == null || matches.isEmpty()) {
                out.warnings.add('Vendor program not found for Training Requirement ref ' + ref);
                continue;
            }

            List<Id> ids = new List<Id>();
            for (Vendor_Customization__c vc : matches) {
                ids.add(vc.Id);
                targetProgramIds.add(vc.Id);
            }
            programIdsByRef.put(ref, ids);
        }

        if (targetProgramIds.isEmpty()) {
            out.warnings.add('No Vendor Program rows resolved for Training Requirement seed.');
            return out;
        }

        Set<String> trainingSystemNames = new Set<String>();
        Set<String> requiredTypeNames = new Set<String>();
        Set<String> externalCourseCodes = new Set<String>();
        for (List<Object> row : scopedRows) {
            String requiredTypeName = row.size() > 2 ? (String) row[2] : null;
            String trainingSystemName = row.size() > 3 ? (String) row[3] : null;
            String externalCourseCode = row.size() > 8 ? (String) row[8] : null;
            if (!String.isBlank(trainingSystemName)) trainingSystemNames.add(trainingSystemName.trim());
            if (!String.isBlank(requiredTypeName)) requiredTypeNames.add(requiredTypeName.trim());
            if (!String.isBlank(externalCourseCode)) externalCourseCodes.add(externalCourseCode.trim());
        }

        Map<String, Training_System__c> trainingSystemByNameKey = new Map<String, Training_System__c>();
        if (!trainingSystemNames.isEmpty()) {
            for (Training_System__c ts : [
                SELECT Id, Name, CreatedDate
                FROM Training_System__c
                WHERE Name IN :trainingSystemNames
                ORDER BY Name ASC, CreatedDate ASC, Id ASC
            ]) {
                String key = normalizeKeyPart(ts.Name);
                if (!trainingSystemByNameKey.containsKey(key)) {
                    trainingSystemByNameKey.put(key, ts);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add(
                        'Duplicate Training System found while resolving Training Requirements for Name "' +
                        ts.Name + '". Using earliest record.'
                    );
                }
            }
        }

        Map<String, Required_Credential__c> requiredByProgramAndType = new Map<String, Required_Credential__c>();
        if (!targetProgramIds.isEmpty()) {
            for (Required_Credential__c rc : [
                SELECT Id, Vendor_Customization__c, External_Contact_Credential_Type__r.Name
                FROM Required_Credential__c
                WHERE Vendor_Customization__c IN :targetProgramIds
            ]) {
                String typeName = rc.External_Contact_Credential_Type__r == null
                    ? null
                    : rc.External_Contact_Credential_Type__r.Name;
                String key = String.valueOf(rc.Vendor_Customization__c) + '|' + normalizeKeyPart(typeName);
                if (!requiredByProgramAndType.containsKey(key)) {
                    requiredByProgramAndType.put(key, rc);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add('Duplicate Required Credential found for Training Requirement key ' + key + '. Using first row.');
                }
            }
        }

        Set<String> validTrainingTypes = new Set<String>();
        String defaultTrainingType;
        for (Schema.PicklistEntry e : Training_Requirement__c.Training_Type__c.getDescribe().getPicklistValues()) {
            if (!e.isActive()) continue;
            validTrainingTypes.add(e.getValue());
            if (defaultTrainingType == null) defaultTrainingType = e.getValue();
        }
        if (String.isBlank(defaultTrainingType)) defaultTrainingType = 'None';

        Map<String, Training_Requirement__c> existingByExternalCode = new Map<String, Training_Requirement__c>();
        Map<String, Training_Requirement__c> existingByInternalKey = new Map<String, Training_Requirement__c>();
        Map<Id, Training_Requirement__c> existingById = new Map<Id, Training_Requirement__c>();

        for (Training_Requirement__c tr : [
            SELECT Id, Vendor_Customization__c, Required_Credential__c, Training_System__c, Training_Type__c,
                   Is_Required__c, Sequence__c, Training_Code__c, External_Course_Code__c, External_Course_Name__c,
                   CreatedDate
            FROM Training_Requirement__c
            WHERE Vendor_Customization__c IN :targetProgramIds
            ORDER BY CreatedDate ASC, Id ASC
        ]) {
            existingById.put(tr.Id, tr);
        }

        if (!externalCourseCodes.isEmpty()) {
            for (Training_Requirement__c tr : [
                SELECT Id, Vendor_Customization__c, Required_Credential__c, Training_System__c, Training_Type__c,
                       Is_Required__c, Sequence__c, Training_Code__c, External_Course_Code__c, External_Course_Name__c,
                       CreatedDate
                FROM Training_Requirement__c
                WHERE External_Course_Code__c IN :externalCourseCodes
                ORDER BY CreatedDate ASC, Id ASC
            ]) {
                if (!existingById.containsKey(tr.Id)) existingById.put(tr.Id, tr);
            }
        }

        for (Training_Requirement__c tr : existingById.values()) {
            if (!String.isBlank(tr.External_Course_Code__c)) {
                String extKey = normalizeKeyPart(tr.External_Course_Code__c);
                if (!existingByExternalCode.containsKey(extKey)) {
                    existingByExternalCode.put(extKey, tr);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add(
                        'Duplicate existing Training Requirement found for External Course Code "' +
                        tr.External_Course_Code__c + '". Using earliest row.'
                    );
                }
            } else {
                String internalKey = buildTrainingRequirementInternalKey(
                    tr.Vendor_Customization__c,
                    tr.Training_Type__c,
                    tr.Training_System__c,
                    tr.Required_Credential__c,
                    tr.Training_Code__c,
                    tr.External_Course_Name__c
                );
                if (!existingByInternalKey.containsKey(internalKey)) {
                    existingByInternalKey.put(internalKey, tr);
                } else {
                    out.duplicateExistingRowsDetected++;
                    out.warnings.add(
                        'Duplicate existing internal Training Requirement found for key ' +
                        internalKey + '. Using earliest row.'
                    );
                }
            }
        }

        List<Training_Requirement__c> inserts = new List<Training_Requirement__c>();
        List<Training_Requirement__c> updates = new List<Training_Requirement__c>();
        Set<String> processedSeedKeys = new Set<String>();

        for (List<Object> row : scopedRows) {
            String programRef = row.size() > 0 ? (String) row[0] : null;
            Integer programCopyIndex = row.size() > 1 ? (Integer) row[1] : 1;
            String requiredCredentialTypeName = row.size() > 2 ? (String) row[2] : null;
            String trainingSystemName = row.size() > 3 ? (String) row[3] : null;
            String trainingType = row.size() > 4 ? (String) row[4] : null;
            Boolean isRequired = row.size() > 5 ? (Boolean) row[5] : true;
            Integer sequence = row.size() > 6 ? (Integer) row[6] : 1;
            String trainingCode = row.size() > 7 ? (String) row[7] : null;
            String externalCourseCode = row.size() > 8 ? (String) row[8] : null;
            String externalCourseName = row.size() > 9 ? (String) row[9] : null;

            if (programCopyIndex == null || programCopyIndex < 1) programCopyIndex = 1;
            trainingCode = String.isBlank(trainingCode) ? null : trainingCode.trim();
            externalCourseCode = String.isBlank(externalCourseCode) ? null : externalCourseCode.trim();
            externalCourseName = String.isBlank(externalCourseName) ? null : externalCourseName.trim();

            List<Id> candidateProgramIds = programIdsByRef.get(programRef);
            if (candidateProgramIds == null || candidateProgramIds.isEmpty()) {
                out.warnings.add('Skip Training Requirement row, no Vendor Program IDs resolved for ref ' + programRef);
                continue;
            }
            if (programCopyIndex > candidateProgramIds.size()) {
                out.warnings.add(
                    'Skip Training Requirement row for ref ' + programRef +
                    ': requested copy index ' + programCopyIndex +
                    ' but only ' + candidateProgramIds.size() + ' program rows exist.'
                );
                continue;
            }
            Id programId = candidateProgramIds[programCopyIndex - 1];

            if (String.isBlank(trainingType) || !validTrainingTypes.contains(trainingType)) {
                if (!String.isBlank(trainingType) && options.strictPicklists) {
                    out.duplicateSeedRowsSkipped++;
                    out.warnings.add(
                        'Skip Training Requirement row for ref ' + programRef +
                        ' due to invalid Training Type "' + trainingType + '".'
                    );
                    continue;
                }
                trainingType = defaultTrainingType;
            }

            Id trainingSystemId;
            if (!String.isBlank(trainingSystemName)) {
                Training_System__c ts = trainingSystemByNameKey.get(normalizeKeyPart(trainingSystemName));
                if (ts == null) {
                    out.warnings.add(
                        'Skip Training Requirement row for ref ' + programRef +
                        ', missing Training System "' + trainingSystemName + '".'
                    );
                    continue;
                }
                trainingSystemId = ts.Id;
            }

            Id requiredCredentialId;
            if (!String.isBlank(requiredCredentialTypeName)) {
                Required_Credential__c rc = requiredByProgramAndType.get(
                    String.valueOf(programId) + '|' + normalizeKeyPart(requiredCredentialTypeName)
                );
                if (rc == null) {
                    out.warnings.add(
                        'Skip Training Requirement row for ref ' + programRef +
                        ', missing Required Credential type "' + requiredCredentialTypeName + '".'
                    );
                    continue;
                }
                requiredCredentialId = rc.Id;
            }

            if (trainingType == 'Internal' && requiredCredentialId != null) {
                out.warnings.add(
                    'Training Requirement row for ref ' + programRef +
                    ' is Internal, ignoring Required Credential type "' + requiredCredentialTypeName + '".'
                );
                requiredCredentialId = null;
            }

            if (trainingType == 'External') {
                if (requiredCredentialId == null) {
                    out.warnings.add(
                        'Skip Training Requirement row for ref ' + programRef +
                        ': External rows require Required Credential.'
                    );
                    continue;
                }
                if (trainingSystemId == null) {
                    out.warnings.add(
                        'Skip Training Requirement row for ref ' + programRef +
                        ': External rows require Training System.'
                    );
                    continue;
                }
            }

            String seedKey;
            if (!String.isBlank(externalCourseCode)) {
                seedKey = 'external|' + normalizeKeyPart(externalCourseCode);
            } else {
                seedKey = 'internal|' + buildTrainingRequirementInternalKey(
                    programId,
                    trainingType,
                    trainingSystemId,
                    requiredCredentialId,
                    trainingCode,
                    externalCourseName
                );
            }
            if (processedSeedKeys.contains(seedKey)) {
                out.duplicateSeedRowsSkipped++;
                continue;
            }
            processedSeedKeys.add(seedKey);

            Training_Requirement__c existing;
            if (!String.isBlank(externalCourseCode)) {
                existing = existingByExternalCode.get(normalizeKeyPart(externalCourseCode));
            } else {
                existing = existingByInternalKey.get(
                    buildTrainingRequirementInternalKey(
                        programId,
                        trainingType,
                        trainingSystemId,
                        requiredCredentialId,
                        trainingCode,
                        externalCourseName
                    )
                );
            }

            if (existing == null) {
                inserts.add(new Training_Requirement__c(
                    Vendor_Customization__c = programId,
                    Required_Credential__c = requiredCredentialId,
                    Training_System__c = trainingSystemId,
                    Training_Type__c = trainingType,
                    Is_Required__c = isRequired,
                    Sequence__c = sequence,
                    Training_Code__c = trainingCode,
                    External_Course_Code__c = externalCourseCode,
                    External_Course_Name__c = externalCourseName
                ));
            } else {
                Boolean changed = false;
                if (existing.Vendor_Customization__c != programId) { existing.Vendor_Customization__c = programId; changed = true; }
                if (existing.Required_Credential__c != requiredCredentialId) { existing.Required_Credential__c = requiredCredentialId; changed = true; }
                if (existing.Training_System__c != trainingSystemId) { existing.Training_System__c = trainingSystemId; changed = true; }
                if (existing.Training_Type__c != trainingType) { existing.Training_Type__c = trainingType; changed = true; }
                if (existing.Is_Required__c != isRequired) { existing.Is_Required__c = isRequired; changed = true; }
                Integer existingSequence = existing.Sequence__c == null ? null : existing.Sequence__c.intValue();
                if (existingSequence != sequence) { existing.Sequence__c = sequence; changed = true; }
                if (existing.Training_Code__c != trainingCode) { existing.Training_Code__c = trainingCode; changed = true; }
                if (existing.External_Course_Code__c != externalCourseCode) { existing.External_Course_Code__c = externalCourseCode; changed = true; }
                if (existing.External_Course_Name__c != externalCourseName) { existing.External_Course_Name__c = externalCourseName; changed = true; }
                if (changed) updates.add(existing);
            }
        }

        if (!inserts.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.insert(inserts, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.trainingRequirementsInserted++;
                else out.warnings.add(
                    'Training Requirement insert failed [' + String.valueOf(inserts[i].External_Course_Code__c) +
                    '|' + String.valueOf(inserts[i].Training_Code__c) + ']: ' +
                    srs[i].getErrors()[0].getMessage()
                );
            }
        } else {
            out.trainingRequirementsInserted = inserts.size();
        }

        if (!updates.isEmpty() && !options.dryRun) {
            Database.SaveResult[] srs = Database.update(updates, false);
            for (Integer i = 0; i < srs.size(); i++) {
                if (srs[i].isSuccess()) out.trainingRequirementsUpdated++;
                else out.warnings.add(
                    'Training Requirement update failed [' + String.valueOf(updates[i].Id) + ']: ' +
                    srs[i].getErrors()[0].getMessage()
                );
            }
        } else {
            out.trainingRequirementsUpdated = updates.size();
        }

        if (options.cleanupDuplicates) {
            cleanupTrainingRequirementDuplicates(targetProgramIds, out, options);
        }

        return out;
    }

    private static Options normalizeOptions(Options options) {
        Options normalized = options == null ? new Options() : options;
        if (normalized.vendorNames == null) normalized.vendorNames = new Set<String>();
        return normalized;
    }

    private static Set<String> normalizeVendorNames(Set<String> inputNames) {
        Set<String> out = new Set<String>();
        if (inputNames == null) return out;
        for (String name : inputNames) {
            if (!String.isBlank(name)) out.add(name.trim());
        }
        return out;
    }

    private static String normalizeKeyPart(Object value) {
        if (value == null) return '';
        String text = String.valueOf(value);
        if (text == null) return '';
        return text.trim().toLowerCase();
    }

    private static String buildTrainingRequirementInternalKey(
        Id vendorProgramId,
        String trainingType,
        Id trainingSystemId,
        Id requiredCredentialId,
        String trainingCode,
        String externalCourseName
    ) {
        return String.valueOf(vendorProgramId) + '|' +
            normalizeKeyPart(trainingType) + '|' +
            String.valueOf(trainingSystemId) + '|' +
            String.valueOf(requiredCredentialId) + '|' +
            normalizeKeyPart(trainingCode) + '|' +
            normalizeKeyPart(externalCourseName);
    }

    private static void applyCleanupUpdates(List<SObject> rows, String label, Result out, Options options) {
        if (rows == null || rows.isEmpty()) return;
        if (options.dryRun) {
            out.cleanupRowsUpdated += rows.size();
            return;
        }

        Database.SaveResult[] srs = Database.update(rows, false);
        for (Integer i = 0; i < srs.size(); i++) {
            if (srs[i].isSuccess()) {
                out.cleanupRowsUpdated++;
            } else {
                String rowId = String.valueOf(rows[i].get('Id'));
                out.warnings.add(
                    'Cleanup update failed [' + label + '] (' + rowId + '): ' +
                    srs[i].getErrors()[0].getMessage()
                );
            }
        }
    }

    private static void applyCleanupDeletes(List<SObject> rows, String label, Result out, Options options) {
        if (rows == null || rows.isEmpty()) return;
        if (options.dryRun) {
            out.cleanupRowsDeleted += rows.size();
            return;
        }

        Database.DeleteResult[] drs = Database.delete(rows, false);
        for (Integer i = 0; i < drs.size(); i++) {
            if (drs[i].isSuccess()) {
                out.cleanupRowsDeleted++;
            } else {
                String rowId = String.valueOf(rows[i].get('Id'));
                out.warnings.add(
                    'Cleanup delete failed [' + label + '] (' + rowId + '): ' +
                    drs[i].getErrors()[0].getMessage()
                );
            }
        }
    }

    private static void cleanupAgreementTemplateDuplicates(Set<String> agreementNames, Result out, Options options) {
        if (agreementNames == null || agreementNames.isEmpty()) return;

        Map<String, Id> canonicalTemplateIdByKey = new Map<String, Id>();
        Map<Id, Id> duplicateTemplateToCanonical = new Map<Id, Id>();

        for (echosign_dev1__Agreement_Template__c t : [
            SELECT Id, Name, echosign_dev1__Agreement_Type__c, CreatedDate
            FROM echosign_dev1__Agreement_Template__c
            WHERE Name IN :agreementNames
            ORDER BY Name ASC, echosign_dev1__Agreement_Type__c ASC, CreatedDate ASC, Id ASC
        ]) {
            String key = t.Name + '|' + String.valueOf(t.echosign_dev1__Agreement_Type__c);
            if (!canonicalTemplateIdByKey.containsKey(key)) {
                canonicalTemplateIdByKey.put(key, t.Id);
            } else {
                duplicateTemplateToCanonical.put(t.Id, canonicalTemplateIdByKey.get(key));
                out.duplicateExistingRowsDetected++;
            }
        }

        if (duplicateTemplateToCanonical.isEmpty()) return;
        out.warnings.add(
            'Cleanup mode: found ' + duplicateTemplateToCanonical.size() +
            ' duplicate Agreement Template rows. Repointing references and deleting duplicates.'
        );

        List<SObject> vcUpdates = new List<SObject>();
        for (Vendor_Customization__c vc : [
            SELECT Id, Associated_Agreement_Template__c
            FROM Vendor_Customization__c
            WHERE Associated_Agreement_Template__c IN :duplicateTemplateToCanonical.keySet()
        ]) {
            Id canonicalTemplateId = duplicateTemplateToCanonical.get(vc.Associated_Agreement_Template__c);
            if (canonicalTemplateId != null && canonicalTemplateId != vc.Associated_Agreement_Template__c) {
                vc.Associated_Agreement_Template__c = canonicalTemplateId;
                vcUpdates.add(vc);
            }
        }
        applyCleanupUpdates(vcUpdates, 'Vendor Customization agreement template', out, options);

        List<SObject> templateDeletes = new List<SObject>();
        for (Id duplicateTemplateId : duplicateTemplateToCanonical.keySet()) {
            templateDeletes.add(new echosign_dev1__Agreement_Template__c(Id = duplicateTemplateId));
        }
        applyCleanupDeletes(templateDeletes, 'Agreement Template', out, options);
    }

    private static void cleanupAgreementTypeDuplicates(Set<String> agreementTypeNames, Result out, Options options) {
        if (agreementTypeNames == null || agreementTypeNames.isEmpty()) return;

        Map<String, Id> canonicalTypeIdByName = new Map<String, Id>();
        Map<Id, Id> duplicateTypeToCanonical = new Map<Id, Id>();

        for (echosign_dev1__Agreement_Type__c t : [
            SELECT Id, Name, CreatedDate
            FROM echosign_dev1__Agreement_Type__c
            WHERE Name IN :agreementTypeNames
            ORDER BY Name ASC, CreatedDate ASC, Id ASC
        ]) {
            if (!canonicalTypeIdByName.containsKey(t.Name)) {
                canonicalTypeIdByName.put(t.Name, t.Id);
            } else {
                duplicateTypeToCanonical.put(t.Id, canonicalTypeIdByName.get(t.Name));
                out.duplicateExistingRowsDetected++;
            }
        }

        if (duplicateTypeToCanonical.isEmpty()) return;
        out.warnings.add(
            'Cleanup mode: found ' + duplicateTypeToCanonical.size() +
            ' duplicate Agreement Type rows. Repointing templates and deleting duplicates.'
        );

        List<SObject> templateUpdates = new List<SObject>();
        for (echosign_dev1__Agreement_Template__c t : [
            SELECT Id, echosign_dev1__Agreement_Type__c
            FROM echosign_dev1__Agreement_Template__c
            WHERE echosign_dev1__Agreement_Type__c IN :duplicateTypeToCanonical.keySet()
        ]) {
            Id canonicalTypeId = duplicateTypeToCanonical.get(t.echosign_dev1__Agreement_Type__c);
            if (canonicalTypeId != null && canonicalTypeId != t.echosign_dev1__Agreement_Type__c) {
                t.echosign_dev1__Agreement_Type__c = canonicalTypeId;
                templateUpdates.add(t);
            }
        }
        applyCleanupUpdates(templateUpdates, 'Agreement Template agreement type', out, options);

        List<SObject> typeDeletes = new List<SObject>();
        for (Id duplicateTypeId : duplicateTypeToCanonical.keySet()) {
            typeDeletes.add(new echosign_dev1__Agreement_Type__c(Id = duplicateTypeId));
        }
        applyCleanupDeletes(typeDeletes, 'Agreement Type', out, options);
    }

    private static void cleanupCredentialDuplicates(Set<Id> targetProgramIds, Result out, Options options) {
        if (targetProgramIds == null || targetProgramIds.isEmpty()) return;

        Map<String, Id> canonicalTypeIdByKey = new Map<String, Id>();
        Map<Id, Id> duplicateTypeToCanonical = new Map<Id, Id>();

        for (External_Contact_Credential_Type__c t : [
            SELECT Id, Vendor_Customization__c, Name, CreatedDate
            FROM External_Contact_Credential_Type__c
            WHERE Vendor_Customization__c IN :targetProgramIds
            ORDER BY Vendor_Customization__c ASC, Name ASC, CreatedDate ASC, Id ASC
        ]) {
            String key = String.valueOf(t.Vendor_Customization__c) + '|' + t.Name;
            if (!canonicalTypeIdByKey.containsKey(key)) {
                canonicalTypeIdByKey.put(key, t.Id);
            } else {
                duplicateTypeToCanonical.put(t.Id, canonicalTypeIdByKey.get(key));
                out.duplicateExistingRowsDetected++;
            }
        }

        if (!duplicateTypeToCanonical.isEmpty()) {
            out.warnings.add(
                'Cleanup mode: found ' + duplicateTypeToCanonical.size() +
                ' duplicate External Contact Credential Type rows. Repointing child records and deleting duplicates.'
            );

            List<SObject> reqTypeUpdates = new List<SObject>();
            for (Required_Credential__c rc : [
                SELECT Id, External_Contact_Credential_Type__c
                FROM Required_Credential__c
                WHERE Vendor_Customization__c IN :targetProgramIds
                AND External_Contact_Credential_Type__c IN :duplicateTypeToCanonical.keySet()
            ]) {
                Id canonicalTypeId = duplicateTypeToCanonical.get(rc.External_Contact_Credential_Type__c);
                if (canonicalTypeId != null && canonicalTypeId != rc.External_Contact_Credential_Type__c) {
                    rc.External_Contact_Credential_Type__c = canonicalTypeId;
                    reqTypeUpdates.add(rc);
                }
            }
            applyCleanupUpdates(reqTypeUpdates, 'Required Credential type reference', out, options);

            List<SObject> depTypeUpdates = new List<SObject>();
            for (External_Credential_Type_Dependency__c d : [
                SELECT Id, Credential_Type__c, Depends_On__c
                FROM External_Credential_Type_Dependency__c
                WHERE Vendor_Program__c IN :targetProgramIds
                AND (Credential_Type__c IN :duplicateTypeToCanonical.keySet()
                     OR Depends_On__c IN :duplicateTypeToCanonical.keySet())
            ]) {
                Boolean changed = false;
                Id canonicalCredentialTypeId = duplicateTypeToCanonical.get(d.Credential_Type__c);
                if (canonicalCredentialTypeId != null && canonicalCredentialTypeId != d.Credential_Type__c) {
                    d.Credential_Type__c = canonicalCredentialTypeId;
                    changed = true;
                }
                Id canonicalDependsOnId = duplicateTypeToCanonical.get(d.Depends_On__c);
                if (canonicalDependsOnId != null && canonicalDependsOnId != d.Depends_On__c) {
                    d.Depends_On__c = canonicalDependsOnId;
                    changed = true;
                }
                if (changed) depTypeUpdates.add(d);
            }
            applyCleanupUpdates(depTypeUpdates, 'Credential Dependency type reference', out, options);

            List<SObject> typeDeletes = new List<SObject>();
            for (Id duplicateTypeId : duplicateTypeToCanonical.keySet()) {
                typeDeletes.add(new External_Contact_Credential_Type__c(Id = duplicateTypeId));
            }
            applyCleanupDeletes(typeDeletes, 'External Contact Credential Type', out, options);
        }

        Map<String, Id> canonicalRequiredIdByKey = new Map<String, Id>();
        List<SObject> requiredDeletes = new List<SObject>();
        for (Required_Credential__c rc : [
            SELECT Id, Vendor_Customization__c, External_Contact_Credential_Type__c, CreatedDate
            FROM Required_Credential__c
            WHERE Vendor_Customization__c IN :targetProgramIds
            ORDER BY Vendor_Customization__c ASC, External_Contact_Credential_Type__c ASC, CreatedDate ASC, Id ASC
        ]) {
            String key = String.valueOf(rc.Vendor_Customization__c) + '|' + String.valueOf(rc.External_Contact_Credential_Type__c);
            if (!canonicalRequiredIdByKey.containsKey(key)) {
                canonicalRequiredIdByKey.put(key, rc.Id);
            } else {
                requiredDeletes.add(new Required_Credential__c(Id = rc.Id));
                out.duplicateExistingRowsDetected++;
            }
        }
        if (!requiredDeletes.isEmpty()) {
            out.warnings.add(
                'Cleanup mode: deleting ' + requiredDeletes.size() +
                ' duplicate Required Credential rows.'
            );
            applyCleanupDeletes(requiredDeletes, 'Required Credential', out, options);
        }

        Map<String, Id> canonicalDependencyIdByKey = new Map<String, Id>();
        List<SObject> dependencyDeletes = new List<SObject>();
        for (External_Credential_Type_Dependency__c d : [
            SELECT Id, Vendor_Program__c, Credential_Type__c, Depends_On__c, CreatedDate
            FROM External_Credential_Type_Dependency__c
            WHERE Vendor_Program__c IN :targetProgramIds
            ORDER BY Vendor_Program__c ASC, Credential_Type__c ASC, Depends_On__c ASC, CreatedDate ASC, Id ASC
        ]) {
            String key =
                String.valueOf(d.Vendor_Program__c) + '|' +
                String.valueOf(d.Credential_Type__c) + '|' +
                String.valueOf(d.Depends_On__c);
            if (!canonicalDependencyIdByKey.containsKey(key)) {
                canonicalDependencyIdByKey.put(key, d.Id);
            } else {
                dependencyDeletes.add(new External_Credential_Type_Dependency__c(Id = d.Id));
                out.duplicateExistingRowsDetected++;
            }
        }
        if (!dependencyDeletes.isEmpty()) {
            out.warnings.add(
                'Cleanup mode: deleting ' + dependencyDeletes.size() +
                ' duplicate Credential Dependency rows.'
            );
            applyCleanupDeletes(dependencyDeletes, 'Credential Dependency', out, options);
        }
    }

    private static void cleanupTrainingSystemDuplicates(Map<Id, Id> duplicateToCanonical, Result out, Options options) {
        if (duplicateToCanonical == null || duplicateToCanonical.isEmpty()) return;

        out.warnings.add(
            'Cleanup mode: found ' + duplicateToCanonical.size() +
            ' duplicate Training System rows. Repointing Training Requirements and deleting duplicates.'
        );

        List<SObject> trainingRequirementUpdates = new List<SObject>();
        for (Training_Requirement__c tr : [
            SELECT Id, Training_System__c
            FROM Training_Requirement__c
            WHERE Training_System__c IN :duplicateToCanonical.keySet()
        ]) {
            Id canonicalSystemId = duplicateToCanonical.get(tr.Training_System__c);
            if (canonicalSystemId != null && canonicalSystemId != tr.Training_System__c) {
                tr.Training_System__c = canonicalSystemId;
                trainingRequirementUpdates.add(tr);
            }
        }
        applyCleanupUpdates(trainingRequirementUpdates, 'Training Requirement training system', out, options);

        List<SObject> trainingSystemDeletes = new List<SObject>();
        for (Id duplicateSystemId : duplicateToCanonical.keySet()) {
            trainingSystemDeletes.add(new Training_System__c(Id = duplicateSystemId));
        }
        applyCleanupDeletes(trainingSystemDeletes, 'Training System', out, options);
    }

    private static void cleanupTrainingRequirementDuplicates(Set<Id> targetProgramIds, Result out, Options options) {
        if (targetProgramIds == null || targetProgramIds.isEmpty()) return;

        Map<String, Id> canonicalIdByKey = new Map<String, Id>();
        Map<Id, Id> duplicateToCanonical = new Map<Id, Id>();

        for (Training_Requirement__c tr : [
            SELECT Id, Vendor_Customization__c, Required_Credential__c, Training_System__c, Training_Type__c,
                   Training_Code__c, External_Course_Code__c, External_Course_Name__c, CreatedDate
            FROM Training_Requirement__c
            WHERE Vendor_Customization__c IN :targetProgramIds
            ORDER BY CreatedDate ASC, Id ASC
        ]) {
            String key;
            if (!String.isBlank(tr.External_Course_Code__c)) {
                key = 'external|' + normalizeKeyPart(tr.External_Course_Code__c);
            } else {
                key = 'internal|' + buildTrainingRequirementInternalKey(
                    tr.Vendor_Customization__c,
                    tr.Training_Type__c,
                    tr.Training_System__c,
                    tr.Required_Credential__c,
                    tr.Training_Code__c,
                    tr.External_Course_Name__c
                );
            }

            if (!canonicalIdByKey.containsKey(key)) {
                canonicalIdByKey.put(key, tr.Id);
            } else {
                duplicateToCanonical.put(tr.Id, canonicalIdByKey.get(key));
                out.duplicateExistingRowsDetected++;
            }
        }

        if (duplicateToCanonical.isEmpty()) return;
        out.warnings.add(
            'Cleanup mode: found ' + duplicateToCanonical.size() +
            ' duplicate Training Requirement rows. Repointing child records and deleting duplicates.'
        );

        List<SObject> trainingAssignmentUpdates = new List<SObject>();
        for (Training_Assignment__c ta : [
            SELECT Id, Vendor_Training_Requirement__c
            FROM Training_Assignment__c
            WHERE Vendor_Training_Requirement__c IN :duplicateToCanonical.keySet()
        ]) {
            Id canonicalId = duplicateToCanonical.get(ta.Vendor_Training_Requirement__c);
            if (canonicalId != null && canonicalId != ta.Vendor_Training_Requirement__c) {
                ta.Vendor_Training_Requirement__c = canonicalId;
                trainingAssignmentUpdates.add(ta);
            }
        }
        applyCleanupUpdates(trainingAssignmentUpdates, 'Training Assignment training requirement', out, options);

        List<SObject> externalCredentialUpdates = new List<SObject>();
        for (POE_External_Contact_Credential__c ecc : [
            SELECT Id, Training_Requirement__c
            FROM POE_External_Contact_Credential__c
            WHERE Training_Requirement__c IN :duplicateToCanonical.keySet()
        ]) {
            Id canonicalId = duplicateToCanonical.get(ecc.Training_Requirement__c);
            if (canonicalId != null && canonicalId != ecc.Training_Requirement__c) {
                ecc.Training_Requirement__c = canonicalId;
                externalCredentialUpdates.add(ecc);
            }
        }
        applyCleanupUpdates(externalCredentialUpdates, 'External Contact Credential training requirement', out, options);

        List<SObject> deletes = new List<SObject>();
        for (Id duplicateId : duplicateToCanonical.keySet()) {
            deletes.add(new Training_Requirement__c(Id = duplicateId));
        }
        applyCleanupDeletes(deletes, 'Training Requirement', out, options);
    }

    private static List<List<String>> dedupeContractReferenceRows(List<List<String>> rows, Result out) {
        List<List<String>> deduped = new List<List<String>>();
        if (rows == null) return deduped;

        Map<String, String> seenDevByName = new Map<String, String>();
        for (List<String> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String name = row[0];
            String devName = row.size() > 1 ? row[1] : null;
            String nameKey = normalizeKeyPart(name);
            if (String.isBlank(nameKey)) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Skip contract reference row with blank Name.');
                continue;
            }

            String devKey = normalizeKeyPart(devName);
            if (!seenDevByName.containsKey(nameKey)) {
                seenDevByName.put(nameKey, devKey);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenDevByName.get(nameKey) != devKey) {
                    out.warnings.add(
                        'Duplicate contract reference seed row for "' + name +
                        '" has conflicting Developer Name. Keeping first row.'
                    );
                }
            }
        }
        return deduped;
    }

    private static List<List<Object>> dedupeProgramRowsByRef(List<List<Object>> rows, Result out) {
        List<List<Object>> deduped = new List<List<Object>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByRef = new Map<String, String>();
        for (List<Object> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String ref = row.size() > 0 ? (String) row[0] : null;
            String refKey = normalizeKeyPart(ref);
            if (String.isBlank(refKey)) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Skip Vendor Program seed row with blank programRef.');
                continue;
            }

            String signature =
                normalizeKeyPart(row.size() > 1 ? row[1] : null) + '|' +
                normalizeKeyPart(row.size() > 2 ? row[2] : null) + '|' +
                normalizeKeyPart(row.size() > 3 ? row[3] : null) + '|' +
                normalizeKeyPart(row.size() > 4 ? row[4] : null) + '|' +
                normalizeKeyPart(row.size() > 5 ? row[5] : null) + '|' +
                normalizeKeyPart(row.size() > 6 ? row[6] : null) + '|' +
                normalizeKeyPart(row.size() > 7 ? row[7] : null) + '|' +
                normalizeKeyPart(row.size() > 8 ? row[8] : null) + '|' +
                normalizeKeyPart(row.size() > 9 ? row[9] : null) + '|' +
                normalizeKeyPart(row.size() > 10 ? row[10] : null);

            if (!seenSignatureByRef.containsKey(refKey)) {
                seenSignatureByRef.put(refKey, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByRef.get(refKey) != signature) {
                    out.warnings.add(
                        'Duplicate Vendor Program seed row for ref "' + ref +
                        '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }
        return deduped;
    }

    private static List<List<String>> dedupeAgreementRows(List<List<String>> rows, Result out) {
        List<List<String>> deduped = new List<List<String>>();
        if (rows == null) return deduped;

        Set<String> seenKeys = new Set<String>();
        for (List<String> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String key =
                normalizeKeyPart(row.size() > 0 ? row[0] : null) + '|' +
                normalizeKeyPart(row.size() > 1 ? row[1] : null) + '|' +
                normalizeKeyPart(row.size() > 2 ? row[2] : null);

            if (!seenKeys.contains(key)) {
                seenKeys.add(key);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
            }
        }
        return deduped;
    }

    private static List<List<String>> dedupeCredentialProgramLocatorRowsByRef(List<List<String>> rows, Result out) {
        List<List<String>> deduped = new List<List<String>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByRef = new Map<String, String>();
        for (List<String> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String ref = row.size() > 0 ? row[0] : null;
            String refKey = normalizeKeyPart(ref);
            if (String.isBlank(refKey)) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Skip credential program locator row with blank programRef.');
                continue;
            }

            String signature =
                normalizeKeyPart(row.size() > 1 ? row[1] : null) + '|' +
                normalizeKeyPart(row.size() > 2 ? row[2] : null) + '|' +
                normalizeKeyPart(row.size() > 3 ? row[3] : null) + '|' +
                normalizeKeyPart(row.size() > 4 ? row[4] : null) + '|' +
                normalizeKeyPart(row.size() > 5 ? row[5] : null);

            if (!seenSignatureByRef.containsKey(refKey)) {
                seenSignatureByRef.put(refKey, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByRef.get(refKey) != signature) {
                    out.warnings.add(
                        'Duplicate credential program locator row for ref "' + ref +
                        '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }
        return deduped;
    }

    private static List<List<Object>> dedupeCredentialTypeRows(List<List<Object>> rows, Result out) {
        List<List<Object>> deduped = new List<List<Object>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByKey = new Map<String, String>();
        for (List<Object> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String key =
                normalizeKeyPart(row.size() > 0 ? row[0] : null) + '|' +
                normalizeKeyPart(row.size() > 1 ? row[1] : null);
            String signature =
                normalizeKeyPart(row.size() > 2 ? row[2] : null) + '|' +
                normalizeKeyPart(row.size() > 3 ? row[3] : null);

            if (!seenSignatureByKey.containsKey(key)) {
                seenSignatureByKey.put(key, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByKey.get(key) != signature) {
                    out.warnings.add(
                        'Duplicate credential type seed row for key "' + key +
                        '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }
        return deduped;
    }

    private static List<List<Object>> dedupeRequiredCredentialRows(List<List<Object>> rows, Result out) {
        List<List<Object>> deduped = new List<List<Object>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByKey = new Map<String, String>();
        for (List<Object> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String key =
                normalizeKeyPart(row.size() > 0 ? row[0] : null) + '|' +
                normalizeKeyPart(row.size() > 1 ? row[1] : null);
            String signature =
                normalizeKeyPart(row.size() > 2 ? row[2] : null) + '|' +
                normalizeKeyPart(row.size() > 3 ? row[3] : null);

            if (!seenSignatureByKey.containsKey(key)) {
                seenSignatureByKey.put(key, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByKey.get(key) != signature) {
                    out.warnings.add(
                        'Duplicate required credential seed row for key "' + key +
                        '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }
        return deduped;
    }

    private static List<List<String>> dedupeDependencyRows(List<List<String>> rows, Result out) {
        List<List<String>> deduped = new List<List<String>>();
        if (rows == null) return deduped;

        Set<String> seenKeys = new Set<String>();
        for (List<String> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String key =
                normalizeKeyPart(row.size() > 0 ? row[0] : null) + '|' +
                normalizeKeyPart(row.size() > 1 ? row[1] : null) + '|' +
                normalizeKeyPart(row.size() > 2 ? row[2] : null);

            if (!seenKeys.contains(key)) {
                seenKeys.add(key);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
            }
        }
        return deduped;
    }

    private static List<List<Object>> dedupeTrainingSystemRowsByName(List<List<Object>> rows, Result out) {
        List<List<Object>> deduped = new List<List<Object>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByName = new Map<String, String>();
        for (List<Object> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String tsName = row.size() > 0 ? (String) row[0] : null;
            String nameKey = normalizeKeyPart(tsName);
            if (String.isBlank(nameKey)) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Skip Training System seed row with blank Name.');
                continue;
            }

            String signature =
                normalizeKeyPart(row.size() > 1 ? row[1] : null) + '|' +
                normalizeKeyPart(row.size() > 2 ? row[2] : null);

            if (!seenSignatureByName.containsKey(nameKey)) {
                seenSignatureByName.put(nameKey, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByName.get(nameKey) != signature) {
                    out.warnings.add(
                        'Duplicate Training System seed row for Name "' + tsName +
                        '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }
        return deduped;
    }

    private static List<List<Object>> dedupeTrainingRequirementRows(List<List<Object>> rows, Result out) {
        List<List<Object>> deduped = new List<List<Object>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByKey = new Map<String, String>();
        for (List<Object> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String programRef = row.size() > 0 ? (String) row[0] : null;
            Integer programCopyIndex = row.size() > 1 ? (Integer) row[1] : 1;
            String key =
                normalizeKeyPart(programRef) + '|' +
                String.valueOf(programCopyIndex == null ? 1 : programCopyIndex) + '|' +
                normalizeKeyPart(row.size() > 8 ? row[8] : null) + '|' +
                normalizeKeyPart(row.size() > 7 ? row[7] : null);
            String signature =
                normalizeKeyPart(row.size() > 2 ? row[2] : null) + '|' +
                normalizeKeyPart(row.size() > 3 ? row[3] : null) + '|' +
                normalizeKeyPart(row.size() > 4 ? row[4] : null) + '|' +
                normalizeKeyPart(row.size() > 5 ? row[5] : null) + '|' +
                normalizeKeyPart(row.size() > 6 ? row[6] : null) + '|' +
                normalizeKeyPart(row.size() > 9 ? row[9] : null);

            if (String.isBlank(normalizeKeyPart(programRef))) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Skip Training Requirement seed row with blank programRef.');
                continue;
            }

            if (!seenSignatureByKey.containsKey(key)) {
                seenSignatureByKey.put(key, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByKey.get(key) != signature) {
                    out.warnings.add(
                        'Duplicate Training Requirement seed row for key "' + key +
                        '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }

        return deduped;
    }

    private static List<List<Object>> dedupeVendorProgramRequirementTypeRows(List<List<Object>> rows, Result out) {
        List<List<Object>> deduped = new List<List<Object>>();
        if (rows == null) return deduped;

        Map<String, String> seenSignatureByType = new Map<String, String>();
        for (List<Object> row : rows) {
            if (row == null || row.isEmpty()) continue;
            String requirementTypeName = row.size() > 0 ? (String) row[0] : null;
            if (String.isBlank(requirementTypeName)) {
                out.duplicateSeedRowsSkipped++;
                out.warnings.add('Skip Vendor Program Requirement seed row with blank Requirement Type.');
                continue;
            }

            String typeKey = normalizeKeyPart(requirementTypeName);
            String signature =
                normalizeKeyPart(row.size() > 1 ? row[1] : null) + '|' +
                normalizeKeyPart(row.size() > 2 ? row[2] : null) + '|' +
                normalizeKeyPart(row.size() > 3 ? row[3] : null);

            if (!seenSignatureByType.containsKey(typeKey)) {
                seenSignatureByType.put(typeKey, signature);
                deduped.add(row);
            } else {
                out.duplicateSeedRowsSkipped++;
                if (seenSignatureByType.get(typeKey) != signature) {
                    out.warnings.add(
                        'Duplicate Vendor Program Requirement seed row for Requirement Type "' +
                        requirementTypeName + '" has conflicting values. Keeping first row.'
                    );
                }
            }
        }

        return deduped;
    }

    private static Map<String, Boolean> getVendorActiveByName() {
        // Add Vendor: '<Vendor Name>' => <Active__c>
        return new Map<String, Boolean>{
            'Amazon' => false,
            'Brinks' => false,
            'C Spire' => true,
            'Earthlink' => false,
            'Frontier' => true,
            'MDP' => false,
            'Optimum' => false,
            'PerfectVision' => true,
            'Safehaven' => false,
            'Spectrum' => false,
            'T-Mobile' => false,
            'Telogix' => false,
            'Verizon' => true,
            'Viasat' => false,
            'Windstream' => false,
            'WOW' => true
        };
    }

    private static List<List<String>> getContractReferenceRows() {
        // Add Contract Record Type Reference: {Contract_Record_Type_Reference__c.Name, Developer_Name__c}
        return new List<List<String>>{
            new List<String>{'NDA', 'NDA'},
            new List<String>{'New Dealer Application (DOM)', 'NewDLRAPPDOM'},
            new List<String>{'Frontier', 'Frontier'},
            new List<String>{'Verison Flos', 'Verizon_Fios'},
            new List<String>{'C-Spire', 'C_Spire'},
            new List<String>{'WOW', 'WOW'}
        };
    }

    private static List<List<Object>> getProgramRows() {
        // Add Vendor Program:
        // {programRef, vendorName, contractRefName, labelOverride, retailOption, businessVertical, glNeeded, autoNeeded, certHolderNeeded, orderEntryPlatform, copies}
        return new List<List<Object>>{
            new List<Object>{'PV_NDA', 'PerfectVision', 'NDA', null, 'N/A', 'N/A', false, false, false, false, 1},
            // PerfectVision DOM program bases (labels match OnboardV2 / production naming for CMDT Scope_Key__c targets).
            new List<Object>{
                'PV_PROGRAM_BASE_CHUZO',
                'PerfectVision',
                'New Dealer Application (DOM)',
                'Program Base Application - with Chuzo',
                'N/A',
                'N/A',
                false,
                false,
                false,
                false,
                1
            },
            new List<Object>{
                'PV_PROGRAM_BASE_CHUZO_NO_PG',
                'PerfectVision',
                'New Dealer Application (DOM)',
                'Program Base Application - with Chuzo (No Personal Guarantee)',
                'N/A',
                'N/A',
                false,
                false,
                false,
                false,
                1
            },
            new List<Object>{
                'PV_PROGRAM_BASE_NO_CHUZO',
                'PerfectVision',
                'New Dealer Application (DOM)',
                'Program Base Application - without Chuzo',
                'N/A',
                'N/A',
                false,
                false,
                false,
                false,
                1
            },
            new List<Object>{'FRONTIER_NA_NA', 'Frontier', 'Frontier', null, 'National Agent', 'National Agent', true, false, false, true, 1},
            new List<Object>{'FRONTIER_NA_NA_D2D', 'Frontier', 'Frontier', null, 'National Agent', 'National Agent and D2D', true, false, false, true, 1},
            new List<Object>{'FRONTIER_NA_D2D', 'Frontier', 'Frontier', null, 'National Agent', 'D2D', true, false, false, true, 1},
            new List<Object>{'FRONTIER_NR_NR', 'Frontier', 'Frontier', null, 'National Retail', 'National Retail', true, false, false, true, 1},
            new List<Object>{'FRONTIER_NR_NR_NA', 'Frontier', 'Frontier', null, 'National Retail', 'National Retail and National Agent', true, false, false, true, 1},
            new List<Object>{'FRONTIER_NR_NR_D2D', 'Frontier', 'Frontier', null, 'National Retail', 'National Retail and D2D', true, false, false, true, 1},
            new List<Object>{'FRONTIER_NR_ALL', 'Frontier', 'Frontier', null, 'National Retail', 'National Retail, National Agent, and D2D', true, false, false, true, 1},
            new List<Object>{'FRONTIER_AMEND', 'Frontier', 'Frontier', null, 'Amendment', 'N/A', true, false, false, true, 1},
            new List<Object>{'VERIZON_FIOS_D2D', 'Verizon', 'Verison Flos', 'Verizon Fios D2D', 'Fios', 'D2D', true, false, false, true, 1},
            new List<Object>{'CSPIRE_D2D', 'C Spire', 'C-Spire', 'C Spire D2D', 'N/A', 'D2D', true, true, false, true, 1},
            new List<Object>{'WOW_D2D', 'WOW', 'WOW', 'WOW D2D', 'N/A', 'D2D', true, true, false, true, 1}
        };
    }

    private static List<List<String>> getAgreementRows() {
        // Add Agreement Template Link:
        // {programRef, Agreement_Template.Name, Agreement_Type.Name}
        return new List<List<String>>{
            new List<String>{'VERIZON_FIOS_D2D', 'Verizon FIOS - D2D', 'Verizon FIOS'},
            new List<String>{'CSPIRE_D2D', 'C Spire D2D', 'C Spire'},
            new List<String>{'WOW_D2D', 'WOW D2D', 'WOW'},
            new List<String>{'FRONTIER_NA_NA', 'Frontier', 'Frontier'},
            new List<String>{'FRONTIER_NA_NA_D2D', 'Frontier', 'Frontier'},
            new List<String>{'FRONTIER_NA_D2D', 'Frontier', 'Frontier'},
            new List<String>{'FRONTIER_NR_NR', 'Frontier NA and NR', 'Frontier NA and NR'},
            new List<String>{'FRONTIER_NR_NR_NA', 'Frontier NA and NR', 'Frontier NA and NR'},
            new List<String>{'FRONTIER_NR_NR_D2D', 'Frontier NA and NR', 'Frontier NA and NR'},
            new List<String>{'FRONTIER_NR_ALL', 'Frontier NA and NR', 'Frontier NA and NR'},
            new List<String>{'FRONTIER_AMEND', 'Frontier NR Amendment', 'Frontier NR Amendment'},
            new List<String>{'PV_NDA', 'NDA', 'NDA'}
        };
    }

    private static List<List<String>> getCredentialProgramLocatorRows() {
        // Add Vendor Program Locator for credential seed:
        // {programRef, vendorName, contractRefName, label, retailOption, businessVertical}
        return new List<List<String>>{
            new List<String>{'VERIZON_FIOS_D2D', 'Verizon', 'Verison Flos', 'Verizon Fios D2D', 'Fios', 'D2D'},
            new List<String>{'CSPIRE_D2D', 'C Spire', 'C-Spire', 'C Spire D2D', 'N/A', 'D2D'},
            new List<String>{'WOW_D2D', 'WOW', 'WOW', 'WOW D2D', 'N/A', 'D2D'}
        };
    }

    private static List<List<Object>> getCredentialTypeRows() {
        // Add External Contact Credential Type:
        // {programRef, credentialTypeName, Sort_Order__c, Active__c}
        return new List<List<Object>>{
            new List<Object>{'CSPIRE_D2D', 'Employee ID', 1, true},
            new List<Object>{'CSPIRE_D2D', 'Initial Password', 1, true},
            new List<Object>{'CSPIRE_D2D', 'Username/ID', 1, true},
            new List<Object>{'CSPIRE_D2D', 'First-Time Username', 1, true},
            new List<Object>{'VERIZON_FIOS_D2D', 'SSO ID', 4, true},
            new List<Object>{'VERIZON_FIOS_D2D', 'CIM Workers #', 1, true},
            new List<Object>{'VERIZON_FIOS_D2D', 'PIN', 3, true},
            new List<Object>{'VERIZON_FIOS_D2D', 'EID', 2, true},
            new List<Object>{'VERIZON_FIOS_D2D', 'Optix Profile ID', 1, true},
            new List<Object>{'WOW_D2D', 'Sales ID', 1, true},
            new List<Object>{'WOW_D2D', 'Partner Email', 1, true},
            new List<Object>{'WOW_D2D', 'Initial Password', 1, true},
            new List<Object>{'WOW_D2D', 'Username/ID', 1, true}
        };
    }

    private static List<List<Object>> getRequiredCredentialRows() {
        // Add Required Credential:
        // {programRef, credentialTypeName, Is_Required__c, Sequence__c}
        return new List<List<Object>>{
            new List<Object>{'VERIZON_FIOS_D2D', 'SSO ID', true, 1},
            new List<Object>{'VERIZON_FIOS_D2D', 'CIM Workers #', true, 1},
            new List<Object>{'VERIZON_FIOS_D2D', 'EID', true, 1},
            new List<Object>{'VERIZON_FIOS_D2D', 'PIN', true, 1},
            new List<Object>{'CSPIRE_D2D', 'Initial Password', true, 1},
            new List<Object>{'CSPIRE_D2D', 'Username/ID', true, 1},
            new List<Object>{'CSPIRE_D2D', 'Employee ID', true, 1},
            new List<Object>{'CSPIRE_D2D', 'First-Time Username', true, 1},
            new List<Object>{'WOW_D2D', 'Username/ID', true, 1},
            new List<Object>{'WOW_D2D', 'Initial Password', true, 1},
            new List<Object>{'VERIZON_FIOS_D2D', 'Optix Profile ID', true, 0},
            new List<Object>{'WOW_D2D', 'Sales ID', true, 1},
            new List<Object>{'WOW_D2D', 'Partner Email', true, 1}
        };
    }

    private static List<List<String>> getDependencyRows() {
        // Add Credential Dependency:
        // {programRef, Credential_Type.Name, Depends_On.Name}
        return new List<List<String>>{
            new List<String>{'VERIZON_FIOS_D2D', 'SSO ID', 'PIN'},
            new List<String>{'VERIZON_FIOS_D2D', 'SSO ID', 'EID'},
            new List<String>{'VERIZON_FIOS_D2D', 'SSO ID', 'CIM Workers #'}
        };
    }

    /**
     * Optional per-programRef Vendor_Program_Requirement__c rows (OnboardV2 / production-aligned).
     * Row shape: {Requirement_Type__c, Sequence__c, Is_Required__c, Active__c}.
     * Program refs without an entry use getDefaultVendorProgramRequirementTypeRows() (or input-label rows).
     */
    private static Map<String, List<List<Object>>> getVendorProgramRequirementRowsByProgramRef() {
        return new Map<String, List<List<Object>>>{
            'PV_NDA' => new List<List<Object>>{
                new List<Object>{ 'Contract', 1, true, true },
                new List<Object>{ 'Agreement', 2, true, true }
            },
            'PV_PROGRAM_BASE_CHUZO' => new List<List<Object>>{
                new List<Object>{ 'Contract', 1, true, true },
                new List<Object>{ 'Agreement', 2, true, true },
                new List<Object>{ 'Credit Check', 3, true, true },
                new List<Object>{ 'Chuzo Agreement', 4, true, true },
                new List<Object>{ 'Background Check', 5, true, true },
                new List<Object>{ 'Driver\'s License', 6, true, true },
                new List<Object>{ 'Business License', 7, true, true },
                new List<Object>{ 'Compliance', 8, true, true },
                new List<Object>{ 'Net Terms', 9, true, true },
                new List<Object>{ 'Personal Guarantee', 10, true, true },
                new List<Object>{ 'Employment Form', 11, true, true },
                new List<Object>{ 'Training', 12, true, true },
                new List<Object>{ 'ERP Setup', 13, true, true }
            },
            'PV_PROGRAM_BASE_CHUZO_NO_PG' => new List<List<Object>>{
                new List<Object>{ 'Contract', 1, true, true },
                new List<Object>{ 'Agreement', 2, true, true },
                new List<Object>{ 'Chuzo Agreement', 3, true, true },
                new List<Object>{ 'Background Check', 4, true, true },
                new List<Object>{ 'Credit Check', 5, true, true },
                new List<Object>{ 'Driver\'s License', 6, true, true },
                new List<Object>{ 'Business License', 7, true, true },
                new List<Object>{ 'Compliance', 8, true, true },
                new List<Object>{ 'Net Terms', 9, true, true },
                new List<Object>{ 'Employment Form', 10, true, true },
                new List<Object>{ 'Training', 11, true, true },
                new List<Object>{ 'ERP Setup', 12, true, true }
            },
            'PV_PROGRAM_BASE_NO_CHUZO' => new List<List<Object>>{
                new List<Object>{ 'Contract', 1, true, true },
                new List<Object>{ 'Agreement', 2, true, true },
                new List<Object>{ 'Chuzo Agreement', 3, true, true },
                new List<Object>{ 'Background Check', 4, true, true },
                new List<Object>{ 'Credit Check', 5, true, true },
                new List<Object>{ 'Driver\'s License', 6, true, true },
                new List<Object>{ 'Business License', 7, true, true },
                new List<Object>{ 'Compliance', 8, true, true },
                new List<Object>{ 'Employment Form', 9, true, true },
                new List<Object>{ 'Net Terms', 10, true, true },
                new List<Object>{ 'Personal Guarantee', 11, true, true },
                new List<Object>{ 'Training', 12, true, true },
                new List<Object>{ 'ERP Setup', 13, true, true }
            }
        };
    }

    private static List<List<Object>> getDefaultVendorProgramRequirementTypeRows() {
        // Add default Vendor Program Requirement rows:
        // {Requirement_Type__c, Sequence__c, Is_Required__c, Active__c}
        return new List<List<Object>>{
            new List<Object>{'Agreement', 1, true, true},
            new List<Object>{'Contract', 1, true, true},
            new List<Object>{'Chuzo Agreement', 1, true, true},
            new List<Object>{'Background Check', 1, true, true},
            new List<Object>{'Credit Check', 1, true, true},
            new List<Object>{'Driver\'s License', 1, true, true},
            new List<Object>{'Business License', 1, true, true},
            new List<Object>{'Compliance', 1, true, true},
            new List<Object>{'ERP Setup', 1, true, true},
            new List<Object>{'Training', 1, true, true},
            new List<Object>{'Net Terms', 1, true, true},
            new List<Object>{'Personal Guarantee', 1, true, true},
            new List<Object>{'Employment Form', 1, true, true}
        };
    }

    private static List<List<Object>> getInputVendorProgramRequirementTypeRows() {
        // Add custom Vendor Program Requirement rows when Vendor Program Label__c = 'input':
        // {Requirement_Type__c, Sequence__c, Is_Required__c, Active__c}
        // Leave empty to intentionally skip default requirements for 'input' labels.
        return new List<List<Object>>{
        };
    }

    private static List<List<Object>> getTrainingRequirementRows() {
        // Add Training Requirement:
        // {programRef, programCopyIndex, requiredCredentialTypeName, trainingSystemName, trainingType, isRequired, sequence, trainingCode, externalCourseCode, externalCourseName}
        return new List<List<Object>>{
            new List<Object>{'PV_PROGRAM_BASE_CHUZO', 1, null, 'LearnUpon', 'Internal', true, 1, '783862', null, null},
            new List<Object>{'PV_PROGRAM_BASE_CHUZO_NO_PG', 1, null, 'LearnUpon', 'Internal', true, 1, '783862', null, null},
            new List<Object>{'FRONTIER_NA_NA', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'FRONTIER_NA_NA_D2D', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'FRONTIER_NA_D2D', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'FRONTIER_NR_NR', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'FRONTIER_NR_NR_NA', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'FRONTIER_NR_NR_D2D', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'FRONTIER_NR_ALL', 1, null, 'LearnUpon', 'Internal', true, 1, '783859', null, null},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'CPNI 2025 Annual Training - Third Parties', 'VZ154364'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'FCC Broadband Label for VCG - 2025', 'VZ154774'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Intro to Wireless for RSS', 'VZ154335'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Mobile Sale Requirements', 'VZ151889'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Portable Electronics Insurance (PIE) Training: 2025 (All States)', 'VZ154587'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'RSS Flex 2.0 Order Process', 'VZ153801'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', false, 1, null, 'RSS Onboarding Benes- Waiver Guidelines-Certs', 'VZ125211'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', false, 1, null, 'RSS Onboarding Do No Solicit', 'VZ125487'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Selling with Integrity for RSS/VEC', 'VZ154077'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'State Comprehensive Privacy Laws- Consumer', 'VZ135918'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Verizon Home Device Protect (VHDP) Refresh 2024', 'VZ152837'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', false, 1, null, 'Verizon Sales Agent Standards of Conduct - 2024', 'VZ152337'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', false, 1, null, 'RSS Onboarding CD2D Weekly Compliance Checklist', 'VZ127680'},
            new List<Object>{'CSPIRE_D2D', 1, null, 'LearnUpon', 'Internal', true, 1, '1034719', null, null},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Verizon Sales Agent Standards of Conduct - 2025', 'VZ154830'},
            new List<Object>{'VERIZON_FIOS_D2D', 1, 'SSO ID', 'Verizon', 'External', true, 1, null, 'Compliance Onboarding for RSS: D2D', 'VZ156026'},
            new List<Object>{'WOW_D2D', 1, null, 'LearnUpon', 'Internal', true, 1, '1034717', null, null}
        };
    }

    private static List<List<Object>> getTrainingSystemRows() {
        // Add Training System:
        // {trainingSystemName, Active__c, System_Type__c}
        return new List<List<Object>>{
            new List<Object>{'LearnUpon', true, 'Internal'},
            new List<Object>{'Verizon', true, 'External'}
        };
    }
}
