from pathlib import Path
import shutil
import tempfile
import unittest
from tools.validate_dm import ROOT,ValidationError
from tools.validate_rap import validate

class RapContractTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        shutil.copytree(ROOT/'src',self.root/'src');shutil.copytree(ROOT/'docs',self.root/'docs')
    def mutate(self,path,before,after):
        p=self.root/path;s=p.read_text();self.assertIn(before,s);p.write_text(s.replace(before,after,1))
    def test_valid_contract(self):
        self.assertIn('4 behavior pools',validate(self.root))
    def test_wrong_behavior_persistence_mapping(self):
        self.mutate('src/yi_dm_dato.bdef.asbdef','Valor = valor;','Valor = campo_id;')
        with self.assertRaisesRegex(ValidationError,'Behavior mapping'):validate(self.root)
    def test_missing_etag(self):
        self.mutate('src/yi_dm_sol.bdef.asbdef','etag master LastChangedAt','')
        with self.assertRaisesRegex(ValidationError,'ETag master'):validate(self.root)
    def test_wrong_composition_redirect(self):
        self.mutate('src/yc_dm_seg.ddls.asddls','composition child YC_DM_SEG_CEN','composition child YC_DM_SEG_ALM')
        with self.assertRaisesRegex(ValidationError,'Composition projection'):validate(self.root)
    def test_missing_field_access_control(self):
        (self.root/'src/yr_i_dm_dato.dcls.asdcls').unlink()
        with self.assertRaisesRegex(ValidationError,'Missing DCL'):validate(self.root)
    def test_service_leaks_security_helper(self):
        self.mutate('src/yui_dm_o4.srvd.srvdsrv','expose YC_DM_DATO as Datos;', 'expose YI_DM_DATO_USR as Datos;')
        with self.assertRaisesRegex(ValidationError,'Public service projection set'):validate(self.root)
    def test_missing_closed_request_guard(self):
        self.mutate('src/ycl_dm_rules.clas.abap',"context-estado <> 'BORRADOR' AND context-estado <> 'EN_CURSO'",'1 = 2')
        with self.assertRaisesRegex(ValidationError,'Closed request guard'):validate(self.root)

    def test_missing_projection_etag(self):
        self.mutate('src/yc_dm_dato.bdef.asbdef','use etag','')
        with self.assertRaisesRegex(ValidationError,'Projection ETag'):validate(self.root)

    def test_missing_lock_during_value_write(self):
        self.mutate('src/ycl_dm_rules.clas.abap','SET LOCKS OF yi_dm_tarea','IGNORED LOCK OF yi_dm_tarea')
        with self.assertRaisesRegex(ValidationError,'Shared task locks'):validate(self.root)
    def test_failed_lock_not_checked_at_save(self):
        self.mutate('src/ybp_i_dm_dato.clas.locals_imp.abap','line_exists( blocked[','line_exists( ignored[')
        with self.assertRaisesRegex(ValidationError,'Failed lock must prevent'):validate(self.root)
