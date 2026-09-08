function report=check_environment()
%CHECK_ENVIRONMENT Read installed products; do not run methods or lease licenses.
%   Missing optional products do not disable unrelated examples. This checks
%   installation only; it does not establish runtime license availability.
catalog=adp_catalog(); products=ver; installed={products.Name};
missing=cell(height(catalog),1); optionalMissing=missing;
for k=1:height(catalog)
    missing{k}=setdiff(catalog.requiredProducts{k},installed,'stable');
    optionalMissing{k}=setdiff(catalog.optionalProducts{k},installed,'stable');
end
report=struct('matlab',version,'release',version('-release'),'computer',computer, ...
    'jvmAvailable',usejava('jvm'),'installedProducts',{installed}, ...
    'methods',table(catalog.method,cellfun(@isempty,missing),missing,optionalMissing, ...
        'VariableNames',{'method','requiredProductsInstalled','missingProducts','missingOptionalProducts'}), ...
    'licenseAvailability','not checked');
disp(report.methods);
end
