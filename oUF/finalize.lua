local parent, ns = ...

-- It's named Private for a reason!
ns.oUF.Private = nil
-- Register oUF with LibStub so ElvUI and plugins can access it via LibStub("oUF")
do
	local minor = 1
	LibStub:AddLib("oUF", "oUF", ns.oUF, minor)
end
