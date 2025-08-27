import {Firestore} from '@google-cloud/firestore';

// Use o emulador (não requer credenciais)
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';

const db = new Firestore({ projectId: 'dev' });

async function seedContracts() {
    const contracts = [
        {
            id: 'CTR-0001',
            summarySubjectContract: 'Recuperação de pavimento AL-101 Norte',
            companyName: 'Construtora Atlântico',
            regionOfState: ['NORTE', 'LITORAL'],
            contractStatus: 'EM ANDAMENTO',
            initialValue: 12000000.00,
            createdAt: new Date(),
            createdBy: 'seed@system'
        },
        {
            id: 'CTR-0002',
            summarySubjectContract: 'Drenagem e sinalização AL-220',
            companyName: 'Via Engenharia',
            regionOfState: ['AGRESTE'],
            contractStatus: 'A INICIAR',
            initialValue: 5400000.00,
            createdAt: new Date(),
            createdBy: 'seed@system'
        },
        {
            id: 'CTR-0003',
            summarySubjectContract: 'Restauração OAE Ponte do Jacaré - AL-215',
            companyName: 'Pontes & Cia',
            regionOfState: ['SERTAO'],
            contractStatus: 'CONCLUIDO',
            initialValue: 3100000.00,
            createdAt: new Date(),
            createdBy: 'seed@system'
        }
    ];

    for (const c of contracts) {
        await db.collection('contracts').doc(c.id).set(c);

        // subcoleção additives
        await db.collection('contracts').doc(c.id)
            .collection('additives').doc('AD-01')
            .set({
            number: 1,
            value: 250000.00,
            description: 'Reforço de base em trecho crítico',
            createdAt: new Date(),
            createdBy: 'seed@system'
        });

        // subcoleção apostilles
        await db.collection('contracts').doc(c.id)
            .collection('apostilles').doc('AP-01')
            .set({
            number: 1,
            value: 15000.00,
            description: 'Ajuste de quantitativos de sinalização',
            createdAt: new Date(),
            createdBy: 'seed@system'
        });

        // subcoleção measurements (ex.: relatório mensal)
        await db.collection('contracts').doc(c.id)
            .collection('measurements').doc('2025-07')
            .set({
            measurementdata: new Date('2025-07-31'),
            valueMeasured: 420000.00,
            reajustesValue: 18000.00,
            revisionsValue: 0.0,
            createdAt: new Date(),
            createdBy: 'seed@system'
        });
    }
}

async function seedAccidents() {
    const accidents = [
        {
            order: 1,
            date: new Date('2025-07-05'),
            type: 'COLISAO',
            city: 'MACEIO',
            latLng: { lat: -9.649849, lng: -35.708949 },
            victims: 2
        },
        {
            order: 2,
            date: new Date('2025-07-11'),
            type: 'ATROPELAMENTO',
            city: 'ARAPIRACA',
            latLng: { lat: -9.754, lng: -36.661 },
            victims: 1
        },
        {
            order: 3,
            date: new Date('2025-07-20'),
            type: 'SAIDA_DE_PISTA',
            city: 'PALMEIRA DOS ÍNDIOS',
            latLng: { lat: -9.405, lng: -36.628 },
            victims: 0
        }
    ];

    const batch = db.batch();
    for (const a of accidents) {
        const ref = db.collection('accidents').doc(a.order.toString().padStart(4, '0'));
        batch.set(ref, {
            ...a,
            createdAt: new Date(),
            createdBy: 'seed@system'
        });
    }
    await batch.commit();
}

async function main() {
    console.log('Seeding Firestore (emulador)…');
    await seedContracts();
    await seedAccidents();
    console.log('OK!');
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
