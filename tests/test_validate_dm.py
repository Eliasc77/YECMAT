"""Regression checks that corrupted repository models cannot pass validation."""
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.validate_dm import ROOT, ValidationError, validate


class ModelValidationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        shutil.copytree(ROOT / 'src', self.root / 'src')
        shutil.copytree(ROOT / 'docs', self.root / 'docs')

    def corrupt(self, name, before, after):
        path = self.root / name
        text = path.read_text()
        self.assertIn(before, text)
        path.write_text(text.replace(before, after, 1))

    def test_valid_repository(self):
        self.assertIn('15 tables', validate(self.root))

    def test_missing_uuid_primary_key(self):
        self.corrupt('src/ymmt_dm_sol.tabl.xml',
                     '<FIELDNAME>SOLICITUD_UUID</FIELDNAME>\n     <KEYFLAG>X</KEYFLAG>',
                     '<FIELDNAME>SOLICITUD_UUID</FIELDNAME>')
        with self.assertRaisesRegex(ValidationError, 'PK'):
            validate(self.root)

    def test_foreign_key_wrong_client_mapping(self):
        self.corrupt('src/ymmt_dm_dato.tabl.xml', '<FORKEY>MANDT</FORKEY>', '<FORKEY>CAMPO_ID</FORKEY>')
        with self.assertRaisesRegex(ValidationError, 'FK mapping'):
            validate(self.root)

    def test_unique_request_number_weakened(self):
        self.corrupt('src/ymmt_dm_sol.tabl.xml', '<UNIQUEFLAG>X</UNIQUEFLAG>', '<UNIQUEFLAG />')
        with self.assertRaisesRegex(ValidationError, 'Index uniqueness'):
            validate(self.root)

    def test_uuid_type_changed(self):
        self.corrupt('src/ymmt_dm_sol.tabl.xml', '<ROLLNAME>SYSUUID_X16</ROLLNAME>', '<ROLLNAME>MATNR</ROLLNAME>')
        with self.assertRaisesRegex(ValidationError, 'Data element'):
            validate(self.root)

    def test_context_length_changed(self):
        self.corrupt('src/ymmt_dm_seg.tabl.xml', '<LENG>000010</LENG>', '<LENG>000020</LENG>')
        with self.assertRaisesRegex(ValidationError, 'Length'):
            validate(self.root)

    def test_der_cardinality_changed(self):
        self.corrupt('docs/arquitectura/DER_DM.mmd',
                     'YMMT_DM_SEG ||--o| YMMT_DM_SEG_CEN',
                     'YMMT_DM_SEG ||--o{ YMMT_DM_SEG_CEN')
        with self.assertRaisesRegex(ValidationError, 'DER FK edges'):
            validate(self.root)

    def test_missing_table(self):
        (self.root / 'src/ymmt_dm_seg_val.tabl.xml').unlink()
        with self.assertRaisesRegex(ValidationError, '15 TABL'):
            validate(self.root)

    def test_duplicate_table(self):
        source = self.root / 'src/ymmt_dm_sol.tabl.xml'
        shutil.copy(source, source.with_name('duplicate.tabl.xml'))
        with self.assertRaisesRegex(ValidationError, '15 TABL'):
            validate(self.root)

    def test_foreign_key_requires_data_element(self):
        self.corrupt('src/ymmt_dm_regla.tabl.xml',
                     '<ROLLNAME>YMME_DM_FLUJO_ID</ROLLNAME>',
                     '<DATATYPE>CHAR</DATATYPE><LENG>000020</LENG>')
        with self.assertRaisesRegex(ValidationError, 'FK data element required'):
            validate(self.root)

    def test_restricted_standard_fieldname(self):
        self.corrupt('src/ymmt_dm_campo.tabl.xml',
                     '<ROLLNAME>YMME_DM_NOMBRE</ROLLNAME>', '<ROLLNAME>FIELDNAME</ROLLNAME>')
        with self.assertRaisesRegex(ValidationError, 'Restricted standard element'):
            validate(self.root)

    def test_missing_domain(self):
        (self.root / 'src/ymmd_dm_version.doma.xml').unlink()
        with self.assertRaisesRegex(ValidationError, '6 DOMA'):
            validate(self.root)

    def test_incompatible_domain_length(self):
        self.corrupt('src/ymmd_dm_campo_id.doma.xml', '<LENG>000030</LENG>', '<LENG>000020</LENG>')
        with self.assertRaisesRegex(ValidationError, 'Domain length'):
            validate(self.root)


if __name__ == '__main__':
    unittest.main()
